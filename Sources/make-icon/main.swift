import AppKit
import PomodoroCore

// Renders the app icon (the device with the sleeping cat) into an .iconset folder.
// Usage: make-icon <output.iconset>

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: make-icon <output.iconset>\n".utf8))
    exit(64)
}
let output = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func color(_ hex: UInt32) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
    )
}

func roundedRect(_ rect: NSRect, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

/// Drawn on a 1024 canvas, top-left origin, inside Apple's 824pt icon grid.
let artwork = NSImage(size: NSSize(width: 1024, height: 1024), flipped: true) { _ in
    let body = NSRect(x: 100, y: 100, width: 824, height: 824)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
    shadow.shadowBlurRadius = 24
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    shadow.set()
    color(0xC6C6C6).setFill()
    roundedRect(body, 185).fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGradient(starting: color(0xDADADA), ending: color(0xB4B4B4))!.draw(in: roundedRect(body, 185), angle: 90)

    let bezel = NSRect(x: 160, y: 160, width: 704, height: 500)
    color(0x161616).setFill()
    roundedRect(bezel, 120).fill()

    let lcd = bezel.insetBy(dx: 22, dy: 22)
    color(0xA5B795).setFill()
    roundedRect(lcd, 100).fill()

    let sprite = CatSprites.sleeping
    let pixel: CGFloat = 15
    let origin = NSPoint(
        x: lcd.midX - CGFloat(sprite.width) * pixel / 2,
        y: lcd.midY - CGFloat(sprite.height) * pixel / 2 + 10
    )
    // One path for all pixels, so antialiasing doesn't leave seams between neighbours.
    let cat = NSBezierPath()
    for (x, y) in sprite.litPixels {
        cat.appendRect(NSRect(x: origin.x + CGFloat(x) * pixel, y: origin.y + CGFloat(y) * pixel, width: pixel, height: pixel))
    }
    color(0x5E744E).setFill()
    cat.fill()

    let keys: [(NSRect, UInt32, UInt32)] = [
        (NSRect(x: 160, y: 700, width: 340, height: 160), 0xEA3B33, 0xC41916),
        (NSRect(x: 524, y: 700, width: 340, height: 160), 0x5F5F5F, 0x434343),
    ]
    for (rect, top, bottom) in keys {
        NSGradient(starting: color(top), ending: color(bottom))!.draw(in: roundedRect(rect, 44), angle: 90)
    }
    return true
}

let sizes: [(name: String, pixels: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for (name, pixels) in sizes {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    artwork.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent("\(name).png"))
}
