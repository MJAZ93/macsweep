// Draws the DMG window background (660×400 pt) at 1x and 2x:
//   swift scripts/make-dmg-background.swift OUTDIR   → OUTDIR/bg.png, OUTDIR/bg@2x.png
// Icon centres used by dmg-settings.py: MacSweep.app at (170, 210), Applications at (490, 210),
// in Finder coordinates (origin top-left).
import AppKit

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let W: CGFloat = 660, H: CGFloat = 400

func render(scale: CGFloat, to path: String) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(W * scale), pixelsHigh: Int(H * scale),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: W, height: H)   // points, so the 2x image carries 144 dpi
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let full = NSRect(x: 0, y: 0, width: W, height: H)

    NSGradient(colors: [NSColor(red: 0.985, green: 0.980, blue: 1.0, alpha: 1),
                        NSColor(red: 0.925, green: 0.905, blue: 0.985, alpha: 1)])!.draw(in: full, angle: -90)
    // soft glow behind the icons
    for x in [170.0, 490.0] {
        let r: CGFloat = 105
        NSGradient(colors: [NSColor.white.withAlphaComponent(0.95), NSColor.white.withAlphaComponent(0)])!
            .draw(in: NSBezierPath(ovalIn: NSRect(x: x - r, y: H - 210 - r, width: 2 * r, height: 2 * r)),
                  relativeCenterPosition: .zero)
    }

    let purple = NSColor(red: 0.43, green: 0.16, blue: 0.85, alpha: 1)
    func text(_ s: String, _ size: CGFloat, _ weight: NSFont.Weight, _ color: NSColor, y: CGFloat) {
        let style = NSMutableParagraphStyle(); style.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: size, weight: weight),
                                                    .foregroundColor: color, .paragraphStyle: style]
        NSAttributedString(string: s, attributes: attrs).draw(in: NSRect(x: 0, y: y, width: W, height: size * 1.5))
    }
    text("MacSweep", 26, .bold, NSColor(white: 0.12, alpha: 1), y: H - 62)
    text("Disk cleanup for developer Macs", 13, .medium, NSColor(white: 0.42, alpha: 1), y: H - 86)

    // arrow from the app to Applications
    let y = H - 210
    let arrow = NSBezierPath()
    arrow.move(to: NSPoint(x: 258, y: y))
    arrow.curve(to: NSPoint(x: 398, y: y), controlPoint1: NSPoint(x: 300, y: y + 26), controlPoint2: NSPoint(x: 356, y: y + 26))
    arrow.lineWidth = 5
    arrow.lineCapStyle = .round
    arrow.setLineDash([2, 11], count: 2, phase: 0)
    purple.withAlphaComponent(0.85).setStroke()
    arrow.stroke()
    let head = NSBezierPath()
    head.move(to: NSPoint(x: 384, y: y + 14))
    head.line(to: NSPoint(x: 404, y: y - 1))
    head.line(to: NSPoint(x: 380, y: y - 8))
    head.lineWidth = 5
    head.lineCapStyle = .round
    head.lineJoinStyle = .round
    head.stroke()

    text("Drag MacSweep to Applications", 13, .semibold, purple, y: 50)
    text("Arrasta o MacSweep para Aplicações", 11.5, .regular, NSColor(white: 0.45, alpha: 1), y: 30)

    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}
render(scale: 1, to: "\(outDir)/bg.png")
render(scale: 2, to: "\(outDir)/bg@2x.png")
