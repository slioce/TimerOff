namespace TimerOff.Core.Tests;

public class CountdownTests
{
    readonly FakeTime _time = new();
    readonly Countdown _countdown;
    readonly List<int> _ticks = [];
    readonly List<int> _warnings = [];
    int _fires;

    public CountdownTests()
    {
        _countdown = new Countdown(_time);
        _countdown.Tick += _ticks.Add;
        _countdown.Warning += _warnings.Add;
        _countdown.Fired += () => _fires++;
    }

    void Arm(int seconds) => _countdown.Arm(_time.Now.AddSeconds(seconds));

    void Advance(int seconds)
    {
        for (var i = 0; i < seconds; i++)
        {
            _time.Now = _time.Now.AddSeconds(1);
            _countdown.Update();
        }
    }

    [Fact]
    public void ReportsTheFirstTickAtOnceThenEverySecond()
    {
        Arm(3);
        Assert.Equal([3], _ticks);
        Advance(2);
        Assert.Equal([3, 2, 1], _ticks);
        Assert.Equal(1, _countdown.Remaining);
    }

    [Fact]
    public void WarnsOnceWhenTheWarningSecondsAreReached()
    {
        Arm(35);
        Advance(10);
        Assert.Equal([30], _warnings);
    }

    [Fact]
    public void WarnsRightAwayWhenArmedInsideTheWarningWindow()
    {
        Arm(20);
        Assert.Equal([20], _warnings);
    }

    [Fact]
    public void FiresOnceAtZeroAndStops()
    {
        Arm(2);
        Advance(5);
        Assert.Equal(1, _fires);
        Assert.Equal([2, 1, 0], _ticks);
        Assert.False(_countdown.IsArmed);
        Assert.Equal(0, _countdown.Remaining);
    }

    [Fact]
    public void CancelStopsEverything()
    {
        Arm(40);
        Advance(2);
        _countdown.Cancel();
        Advance(50);
        Assert.Equal([40, 39, 38], _ticks);
        Assert.Empty(_warnings);
        Assert.Equal(0, _fires);
        Assert.Null(_countdown.Target);
    }

    [Fact]
    public void ArmingAgainReplacesTheCountdown()
    {
        Arm(35);
        Advance(10);
        Arm(35);
        Advance(10);
        Assert.Equal([30, 30], _warnings);
    }
}
