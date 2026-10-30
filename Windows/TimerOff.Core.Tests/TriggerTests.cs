namespace TimerOff.Core.Tests;

public class TriggerTests
{
    static DateTimeOffset Date(int hour, int minute, int second = 0, int day = 2) =>
        new(2026, 6, day, hour, minute, second, TimeSpan.FromHours(2));

    [Fact]
    public void MinutesAddToNow()
    {
        Assert.Equal(Date(20, 15), new Trigger.After(15).TargetDate(Date(20, 0)));
        Assert.Equal(Date(21, 30), new Trigger.After(90).TargetDate(Date(20, 0)));
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-5)]
    public void ZeroOrNegativeMinutesAreRejected(int minutes)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => new Trigger.After(minutes).TargetDate(Date(20, 0)));
    }

    [Fact]
    public void LaterTimeTodayIsToday()
    {
        Assert.Equal(Date(23, 0), new Trigger.At(23, 0).TargetDate(Date(20, 0)));
    }

    [Fact]
    public void EarlierOrSameTimeIsTomorrow()
    {
        Assert.Equal(Date(8, 30, day: 3), new Trigger.At(8, 30).TargetDate(Date(20, 0)));
        Assert.Equal(Date(20, 0, day: 3), new Trigger.At(20, 0).TargetDate(Date(20, 0)));
        Assert.Equal(Date(20, 0, day: 3), new Trigger.At(20, 0).TargetDate(Date(20, 0, second: 30)));
    }

    [Fact]
    public void SecondsLeftInTheCurrentMinuteCount()
    {
        Assert.Equal(Date(20, 1), new Trigger.At(20, 1).TargetDate(Date(20, 0, second: 40)));
    }

    [Theory]
    [InlineData(24, 0)]
    [InlineData(9, 60)]
    [InlineData(-1, 0)]
    public void OutOfRangeTimesAreRejected(int hour, int minute)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => new Trigger.At(hour, minute).TargetDate(Date(20, 0)));
    }
}
