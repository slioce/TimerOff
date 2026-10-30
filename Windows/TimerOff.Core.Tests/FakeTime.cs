namespace TimerOff.Core.Tests;

/// <summary>A clock the test moves by hand.</summary>
sealed class FakeTime : TimeProvider
{
    public DateTimeOffset Now { get; set; } = new(2026, 6, 2, 20, 0, 0, TimeSpan.FromHours(2));

    public override DateTimeOffset GetUtcNow() => Now.ToUniversalTime();
}
