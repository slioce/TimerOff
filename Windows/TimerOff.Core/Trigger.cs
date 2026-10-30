namespace TimerOff.Core;

/// <summary>When the shutdown should happen: after a number of minutes, or at a time of day.</summary>
public abstract record Trigger
{
    public sealed record After(int Minutes) : Trigger;

    public sealed record At(int Hour, int Minute) : Trigger;

    /// <summary>The absolute moment this trigger stands for. A time of day that has already passed means tomorrow.</summary>
    /// <exception cref="ArgumentOutOfRangeException">The duration is not positive, or the time of day is out of range.</exception>
    public DateTimeOffset TargetDate(DateTimeOffset now)
    {
        switch (this)
        {
            case After(var minutes):
                if (minutes <= 0) throw new ArgumentOutOfRangeException(nameof(minutes), "The duration must be positive.");
                return now.AddMinutes(minutes);
            case At(var hour, var minute):
                if (hour is < 0 or > 23 || minute is < 0 or > 59) throw new ArgumentOutOfRangeException(nameof(hour), "The time of day is out of range.");
                var today = new DateTimeOffset(now.Year, now.Month, now.Day, hour, minute, 0, now.Offset);
                return today > now ? today : today.AddDays(1);
            default:
                throw new InvalidOperationException();
        }
    }
}
