/// Seconds left as a clock reading: `mm:ss` under an hour, `h:mm:ss` from then on.
public func formatRemaining(_ seconds: Int) -> String {
    let seconds = max(0, seconds)
    let hours = seconds / 3600
    let minutes = seconds % 3600 / 60
    let rest = seconds % 60
    let pad = { (n: Int) in n < 10 ? "0\(n)" : "\(n)" }
    return hours > 0 ? "\(hours):\(pad(minutes)):\(pad(rest))" : "\(pad(minutes)):\(pad(rest))"
}
