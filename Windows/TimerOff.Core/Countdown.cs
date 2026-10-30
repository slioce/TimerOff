namespace TimerOff.Core;

/// <summary>
/// Counts down to a target date, reporting the seconds left, a single warning and the moment it fires.
/// The owner calls <see cref="Update"/> once a second; the countdown itself keeps no timer thread.
/// </summary>
public sealed class Countdown(TimeProvider time, int warningSeconds = 30)
{
    private bool _warned;

    public int WarningSeconds { get; } = warningSeconds;

    public event Action<int>? Tick;

    public event Action<int>? Warning;

    public event Action? Fired;

    public DateTimeOffset? Target { get; private set; }

    public bool IsArmed => Target is not null;

    /// <summary>Whole seconds left, never negative; zero when idle.</summary>
    public int Remaining => Target is { } target
        ? Math.Max(0, (int)Math.Round((target - time.GetUtcNow()).TotalSeconds))
        : 0;

    /// <summary>Starts counting down to <paramref name="target"/>, replacing any countdown in progress. Reports the first tick right away.</summary>
    public void Arm(DateTimeOffset target)
    {
        Target = target;
        _warned = false;
        Update();
    }

    /// <summary>Stops the countdown; nothing is reported after this.</summary>
    public void Cancel()
    {
        Target = null;
    }

    /// <summary>Reports the current state. Call it once a second while armed.</summary>
    public void Update()
    {
        if (!IsArmed) return;
        var remaining = Remaining;
        Tick?.Invoke(remaining);
        if (remaining == 0)
        {
            Cancel();
            Fired?.Invoke();
        }
        else if (!_warned && remaining <= WarningSeconds)
        {
            _warned = true;
            Warning?.Invoke(remaining);
        }
    }
}
