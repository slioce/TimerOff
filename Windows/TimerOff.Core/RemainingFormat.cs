namespace TimerOff.Core;

public static class RemainingFormat
{
    /// <summary>Seconds left as a clock reading: <c>mm:ss</c> under an hour, <c>h:mm:ss</c> from then on.</summary>
    public static string Clock(int seconds)
    {
        seconds = Math.Max(0, seconds);
        var hours = seconds / 3600;
        var minutes = seconds % 3600 / 60;
        var rest = seconds % 60;
        return hours > 0 ? $"{hours}:{minutes:00}:{rest:00}" : $"{minutes:00}:{rest:00}";
    }
}
