using System.Diagnostics;

namespace TimerOff;

/// <summary>The one place that touches the system: asks Windows to shut down.</summary>
public static class PowerControl
{
    /// <summary>With <c>TIMEROFF_DRYRUN=1</c> in the environment the shutdown is skipped, so the whole flow can be tried safely.</summary>
    public static bool IsDryRun { get; } = Environment.GetEnvironmentVariable("TIMEROFF_DRYRUN") == "1";

    public static void ShutDown()
    {
        if (IsDryRun) return;
        Process.Start(new ProcessStartInfo("shutdown", "/s /t 0") { UseShellExecute = false, CreateNoWindow = true });
    }
}
