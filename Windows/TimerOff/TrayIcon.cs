using System.Windows.Forms;

namespace TimerOff;

/// <summary>The icon in the notification area, with the remaining time as its tooltip.</summary>
public sealed class TrayIcon : IDisposable
{
    private readonly NotifyIcon _icon = new();
    private readonly ToolStripMenuItem _cancel;

    public TrayIcon(Action show, Action cancel, Action exit)
    {
        _cancel = new ToolStripMenuItem(Strings.CancelTimer, null, (_, _) => cancel()) { Enabled = false };
        var menu = new ContextMenuStrip();
        menu.Items.Add(new ToolStripMenuItem(Strings.ShowWindow, null, (_, _) => show()) { Font = new System.Drawing.Font(menu.Font, System.Drawing.FontStyle.Bold) });
        menu.Items.Add(_cancel);
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add(new ToolStripMenuItem(Strings.Exit, null, (_, _) => exit()));

        _icon.Icon = new System.Drawing.Icon(System.IO.Path.Combine(AppContext.BaseDirectory, "Assets", "TimerOff.ico"));
        _icon.ContextMenuStrip = menu;
        _icon.DoubleClick += (_, _) => show();
        Update(null);
        _icon.Visible = true;
    }

    /// <summary>Shows the remaining time, or that no timer is set.</summary>
    public void Update(string? remaining)
    {
        _icon.Text = remaining is null ? $"{Strings.Title} – {Strings.Idle}" : $"{Strings.Title} – {Strings.ShuttingDownIn} {remaining}";
        _cancel.Enabled = remaining is not null;
    }

    public void Notify(string title, string body)
    {
        _icon.ShowBalloonTip(5000, title, body, ToolTipIcon.Info);
    }

    public void Dispose()
    {
        _icon.Visible = false;
        _icon.Dispose();
    }
}
