namespace TimerOff.Core.Tests;

public class RemainingFormatTests
{
    [Theory]
    [InlineData(0, "00:00")]
    [InlineData(7, "00:07")]
    [InlineData(3599, "59:59")]
    [InlineData(3600, "1:00:00")]
    [InlineData(7384, "2:03:04")]
    [InlineData(-3, "00:00")]
    public void FormatsAsAClock(int seconds, string expected)
    {
        Assert.Equal(expected, RemainingFormat.Clock(seconds));
    }
}
