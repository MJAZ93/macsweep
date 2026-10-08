// Draws the 1024×1024 app icon: swift scripts/make-icon.swift out.png
import AppKit

let size: CGFloat = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.png"
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// macOS icon grid: 824pt rounded square centred on a 1024 canvas
let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
let shape = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)
NSGraphicsContext.current?.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
shadow.shadowOffset = NSSize(width: 0, height: -12)
shadow.shadowBlurRadius = 28
shadow.set()
NSColor(red: 0.43, green: 0.16, blue: 0.85, alpha: 1).setFill()
shape.fill()
NSGraphicsContext.current?.restoreGraphicsState()
NSGradient(colors: [NSColor(red: 0.60, green: 0.38, blue: 0.98, alpha: 1),
                    NSColor(red: 0.36, green: 0.13, blue: 0.75, alpha: 1)])!.draw(in: shape, angle: -90)

// broom handle + sweep line, as in the favicon of the old web page
NSColor.white.setStroke()
let handle = NSBezierPath()
handle.move(to: NSPoint(x: 318, y: 318))
handle.line(to: NSPoint(x: 640, y: 742))
handle.lineWidth = 92
handle.lineCapStyle = .round
handle.stroke()
let sweep = NSBezierPath()
sweep.move(to: NSPoint(x: 476, y: 282))
sweep.line(to: NSPoint(x: 742, y: 282))
sweep.lineWidth = 92
sweep.lineCapStyle = .round
sweep.stroke()
// three dust dots
NSColor.white.withAlphaComponent(0.55).setFill()
for (x, y, r) in [(690.0, 400.0, 30.0), (768.0, 470.0, 22.0), (640.0, 470.0, 18.0)] {
    NSBezierPath(ovalIn: NSRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r)).fill()
}

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
