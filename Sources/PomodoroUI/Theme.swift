import AppKit
import SwiftUI

extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(nsColor: NSColor(hex: hex))
    }

    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? NSColor(hex: dark) : NSColor(hex: light)
        })
    }
}

/// Colors for the popup. The device itself is a physical object, so it keeps the same colors in dark mode.
enum Palette {
    static let bodyTop = Color(hex: 0xD3D3D3)
    static let bodyBottom = Color(hex: 0xB8B8B8)
    static let bezel = Color(hex: 0x161616)
    static let bezelRim = Color(hex: 0x8E8E8E)

    static let lcd = Color(hex: 0xA5B795)
    static let lcdInk = Color(hex: 0x3F5236)
    static let lcdLabel = Color(hex: 0x4B5F41)
    static let lcdSprite = Color(hex: 0x6A8158)

    static let grilleDot = Color(hex: 0x8D8D8D)
    static let grilleDotLit = Color(hex: 0xEDEDED)
    static let grilleDotDark = Color(hex: 0x5E5E5E)

    static let card = Color.adaptive(light: 0xFAFAFA, dark: 0x2C2C2E)
    static let cardText = Color.adaptive(light: 0x2A2A2A, dark: 0xF2F2F2)
    static let cardSecondary = Color.adaptive(light: 0x9B9B9B, dark: 0x8E8E93)
    static let cardHairline = Color.adaptive(light: 0xE4E4E4, dark: 0x434346)
    static let chipFill = Color.adaptive(light: 0xFFFFFF, dark: 0x343437)
    static let selectedFill = Color.adaptive(light: 0x474747, dark: 0xEDEDED)
    static let selectedText = Color.adaptive(light: 0xFFFFFF, dark: 0x1E1E1E)
}

struct KeyPalette {
    let top: Color
    let bottom: Color
    let edge: Color
    let text: Color

    static let red = KeyPalette(
        top: Color(hex: 0xEA3B33), bottom: Color(hex: 0xCB1B18), edge: Color(hex: 0x7A1310), text: .white
    )
    static let graphite = KeyPalette(
        top: Color(hex: 0x5F5F5F), bottom: Color(hex: 0x464646), edge: Color(hex: 0x262626), text: Color(hex: 0xDEDEDE)
    )
}
