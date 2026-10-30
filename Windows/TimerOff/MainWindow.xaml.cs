using System.ComponentModel;
using System.Globalization;
using System.Media;
using System.Windows;
using System.Windows.Media;
using System.Windows.Threading;
using TimerOff.Core;
using Trigger = TimerOff.Core.Trigger;

namespace TimerOff;

public partial class MainWindow : Window
{
    private readonly Countdown _countdown = new(TimeProvider.System);
    private readonly DispatcherTimer _ticker = new() { Interval = TimeSpan.FromSeconds(1) };
    private readonly TrayIcon _tray;
    private readonly Brush _countdownBrush;

    public MainWindow()
    {
        InitializeComponent();
        _countdownBrush = CountdownText.Foreground;
        _tray = new TrayIcon(ShowWindow, CancelTimer, Exit);
        _ticker.Tick += (_, _) => _countdown.Update();
        _countdown.Tick += OnTick;
        _countdown.Warning += OnWarning;
        _countdown.Fired += OnFired;
    }

    // Arming

    private void OnPreset(object sender, RoutedEventArgs e)
    {
        Arm(new Trigger.After(int.Parse((string)((FrameworkElement)sender).Tag, CultureInfo.InvariantCulture)));
    }

    private void OnStart(object sender, RoutedEventArgs e)
    {
        if (AfterMode.IsChecked == true)
        {
            if (!int.TryParse(HoursBox.Text, out var hours) || !int.TryParse(MinutesBox.Text, out var minutes) || hours * 60 + minutes <= 0)
            {
                ShowError(Strings.InvalidDuration);
                return;
            }
            Arm(new Trigger.After(hours * 60 + minutes));
        }
        else
        {
            if (!TimeOnly.TryParse(TimeBox.Text, CultureInfo.CurrentCulture, out var time))
            {
                ShowError(Strings.InvalidTime);
                return;
            }
            Arm(new Trigger.At(time.Hour, time.Minute));
        }
    }

    private void Arm(Trigger trigger)
    {
        DateTimeOffset target;
        try
        {
            target = trigger.TargetDate(DateTimeOffset.Now);
        }
        catch (ArgumentOutOfRangeException)
        {
            ShowError(trigger is Trigger.After ? Strings.InvalidDuration : Strings.InvalidTime);
            return;
        }
        ErrorText.Visibility = Visibility.Collapsed;
        ArmedLabel.Text = Strings.ShuttingDownAt(target);
        CountdownText.Foreground = _countdownBrush;
        WarningText.Visibility = Visibility.Hidden;
        IdleView.Visibility = Visibility.Collapsed;
        ArmedView.Visibility = Visibility.Visible;
        _countdown.Arm(target);
        _ticker.Start();
    }

    private void OnCancel(object sender, RoutedEventArgs e) => CancelTimer();

    private void CancelTimer()
    {
        _countdown.Cancel();
        ShowIdle();
    }

    // Countdown events

    private void OnTick(int remaining)
    {
        var clock = RemainingFormat.Clock(remaining);
        CountdownText.Text = clock;
        _tray.Update(clock);
    }

    private void OnWarning(int remaining)
    {
        CountdownText.Foreground = new SolidColorBrush(Color.FromRgb(0xD1, 0x34, 0x38));
        WarningText.Visibility = Visibility.Visible;
        ShowWindow();
        Topmost = true;
        SystemSounds.Exclamation.Play();
    }

    private void OnFired()
    {
        ShowIdle();
        if (PowerControl.IsDryRun) _tray.Notify(Strings.DryRunTitle, Strings.DryRunBody);
        PowerControl.ShutDown();
    }

    // Views and lifecycle

    private void ShowIdle()
    {
        _ticker.Stop();
        Topmost = false;
        ArmedView.Visibility = Visibility.Collapsed;
        IdleView.Visibility = Visibility.Visible;
        _tray.Update(null);
    }

    private void ShowError(string message)
    {
        ErrorText.Text = message;
        ErrorText.Visibility = Visibility.Visible;
    }

    private void ShowWindow()
    {
        Show();
        if (WindowState == WindowState.Minimized) WindowState = WindowState.Normal;
        Activate();
    }

    private void OnTimeFocus(object sender, RoutedEventArgs e)
    {
        AtMode.IsChecked = true;
    }

    /// <summary>The close button hides the window; the app keeps running in the tray until Exit.</summary>
    private void OnClosing(object? sender, CancelEventArgs e)
    {
        e.Cancel = true;
        Hide();
    }

    private void Exit()
    {
        _countdown.Cancel();
        _tray.Dispose();
        Application.Current.Shutdown();
    }
}
