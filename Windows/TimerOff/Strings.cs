using System.Globalization;

namespace TimerOff;

/// <summary>The app's texts, in the language of the user's Windows account: English, or Italian.</summary>
public static class Strings
{
    private static readonly bool Italian = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "it";

    private static string T(string english, string italian) => Italian ? italian : english;

    public static string Title => "TimerOff";
    public static string Tagline => T("Shut down this PC later", "Spegni questo PC più tardi");
    public static string Minutes15 => T("15 minutes", "15 minuti");
    public static string Minutes30 => T("30 minutes", "30 minuti");
    public static string Hour1 => T("1 hour", "1 ora");
    public static string Hours2 => T("2 hours", "2 ore");
    public static string AfterDuration => T("After", "Dopo");
    public static string Hours => T("h", "h");
    public static string MinutesShort => T("min", "min");
    public static string AtTime => T("At", "Alle");
    public static string Start => T("Start", "Avvia");
    public static string InvalidDuration => T("Enter a duration of at least one minute.", "Inserisci una durata di almeno un minuto.");
    public static string InvalidTime => T("Enter a time as HH:MM.", "Inserisci un orario come HH:MM.");
    public static string ShuttingDownIn => T("Shutting down in", "Spegnimento tra");
    public static string SaveYourWork => T("Save your work, or cancel the timer.", "Salva il tuo lavoro, o annulla il timer.");
    public static string Cancel => T("Cancel", "Annulla");
    public static string ShowWindow => T("Show TimerOff", "Mostra TimerOff");
    public static string CancelTimer => T("Cancel timer", "Annulla timer");
    public static string Exit => T("Exit", "Esci");
    public static string Idle => T("No timer set", "Nessun timer impostato");
    public static string DryRunTitle => T("Dry run", "Prova a vuoto");
    public static string DryRunBody => T("The PC would shut down now.", "Il PC si spegnerebbe adesso.");

    public static string ShuttingDownAt(DateTimeOffset target)
    {
        var time = target.ToString("t", CultureInfo.CurrentCulture);
        var today = target.Date == DateTimeOffset.Now.Date;
        return today ? T($"Shutting down at {time}", $"Spegnimento alle {time}") : T($"Shutting down tomorrow at {time}", $"Spegnimento domani alle {time}");
    }
}
