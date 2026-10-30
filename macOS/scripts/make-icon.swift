// Draws the app icon and writes it as an Xcode app icon set (PNGs plus Contents.json).
// With a second path it also writes the Windows assets there: the MSIX logos and TimerOff.ico.
// Usage: swift scripts/make-icon.swift TimerOff/Resources/Assets.xcassets/AppIcon.appiconset [../Windows/TimerOff/Assets]
import AppKit

let arguments = CommandLine.arguments.dropFirst()
let output = URL(fileURLWithPath: arguments.first ?? "AppIcon.appiconset")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

/// Renders a `width` × `height` pixel image with the icon, drawn on Apple's 1024-point grid, centered and scaled to the shorter side.
func render(width: Int, height: Int, inset: CGFloat = 0) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: width, height: height)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let side = CGFloat(min(width, height)) * (1 - inset)
    let transform = NSAffineTransform()
    transform.translateX(by: (CGFloat(width) - side) / 2, yBy: (CGFloat(height) - side) / 2)
    transform.scale(by: side / 1024)
    transform.concat()

    let tile = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)
    let shadow = NSShadow()
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    shadow.shadowBlurRadius = 24
    shadow.shadowColor = NSColor(white: 0, alpha: 0.3)
    shadow.set()
    NSColor.black.setFill()
    tile.fill()
    NSShadow().set()
    NSGradient(
        starting: NSColor(srgbRed: 1.00, green: 0.45, blue: 0.25, alpha: 1),
        ending: NSColor(srgbRed: 0.76, green: 0.10, blue: 0.24, alpha: 1)
    )!.draw(in: tile, angle: -90)

    let config = NSImage.SymbolConfiguration(pointSize: 430, weight: .semibold)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    let symbol = NSImage(systemSymbolName: "power", accessibilityDescription: nil)!.withSymbolConfiguration(config)!
    let size = symbol.size
    symbol.draw(in: NSRect(x: 512 - size.width / 2, y: 512 - size.height / 2, width: size.width, height: size.height))

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

// macOS icon set
var images: [[String: String]] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
        try render(width: points * scale, height: points * scale).write(to: output.appendingPathComponent(name))
        images.append(["filename": name, "idiom": "mac", "scale": "\(scale)x", "size": "\(points)x\(points)"])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: output.appendingPathComponent("Contents.json"))

// Windows assets: MSIX logos (the tile has its own margin, so no inset) and a multi-size .ico for the window and the tray.
if let windows = arguments.dropFirst().first.map({ URL(fileURLWithPath: $0) }) {
    try FileManager.default.createDirectory(at: windows, withIntermediateDirectories: true)
    for (name, width, height) in [("Square44x44Logo", 44, 44), ("Square150x150Logo", 150, 150), ("Wide310x150Logo", 310, 150), ("StoreLogo", 50, 50)] {
        try render(width: width, height: height).write(to: windows.appendingPathComponent("\(name).png"))
    }

    let sizes = [16, 32, 48, 256]
    let pngs = sizes.map { render(width: $0, height: $0, inset: -0.18) }  // the tile fills the square, as Windows icons do
    var ico = Data()
    func append(_ value: UInt16) { withUnsafeBytes(of: value.littleEndian) { ico.append(contentsOf: $0) } }
    func append(_ value: UInt32) { withUnsafeBytes(of: value.littleEndian) { ico.append(contentsOf: $0) } }
    append(UInt16(0)); append(UInt16(1)); append(UInt16(sizes.count))
    var offset = 6 + 16 * sizes.count
    for (size, png) in zip(sizes, pngs) {
        ico.append(UInt8(size == 256 ? 0 : size)); ico.append(UInt8(size == 256 ? 0 : size))
        ico.append(0); ico.append(0)
        append(UInt16(1)); append(UInt16(32))
        append(UInt32(png.count)); append(UInt32(offset))
        offset += png.count
    }
    for png in pngs { ico.append(png) }
    try ico.write(to: windows.appendingPathComponent("TimerOff.ico"))
}
