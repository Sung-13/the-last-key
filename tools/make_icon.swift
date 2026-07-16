import AppKit

func hexColor(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1)
}

let amber = hexColor(0xF59E0B)
let coral = hexColor(0xF4715F)
let charcoal = hexColor(0x1C1917)

// White-filled key.fill glyph rendered from SF Symbols.
func whiteGlyph() -> NSImage {
    let config = NSImage.SymbolConfiguration(pointSize: 600, weight: .medium)
    guard let symbol = NSImage(systemSymbolName: "key.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) else {
        fatalError("key.fill symbol unavailable")
    }
    let img = NSImage(size: symbol.size)
    img.lockFocus()
    symbol.draw(in: NSRect(origin: .zero, size: symbol.size))
    NSColor.white.set()
    NSRect(origin: .zero, size: symbol.size).fill(using: .sourceIn)
    img.unlockFocus()
    return img
}

// Same glyph filled with the sunrise gradient instead of white.
func gradientGlyph(_ base: NSImage) -> NSImage {
    let img = NSImage(size: base.size)
    img.lockFocus()
    NSGradient(starting: amber, ending: coral)!
        .draw(in: NSRect(origin: .zero, size: base.size), angle: -60)
    base.draw(in: NSRect(origin: .zero, size: base.size),
              from: .zero, operation: .destinationIn, fraction: 1)
    img.unlockFocus()
    return img
}

func renderIcon(named name: String, glyph: NSImage, shadow useShadow: Bool,
                background: ((NSRect) -> Void)?) {
    let px = 1024
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .calibratedRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: px, height: px)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let full = NSRect(x: 0, y: 0, width: px, height: px)
    background?(full)

    let aspect = glyph.size.height / glyph.size.width
    let w: CGFloat = 640
    let h = w * aspect
    let rect = NSRect(x: (CGFloat(px) - w) / 2, y: (CGFloat(px) - h) / 2, width: w, height: h)

    if useShadow {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.20)
        shadow.shadowBlurRadius = 26
        shadow.shadowOffset = NSSize(width: 0, height: -12)
        shadow.set()
    }
    glyph.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)

    NSGraphicsContext.restoreGraphicsState()
    let png = rep.representation(using: .png, properties: [:])!
    let out = CommandLine.arguments[1] + "/" + name
    try! png.write(to: URL(fileURLWithPath: out))
    print("wrote \(out)")
}

let white = whiteGlyph()
let gradient = gradientGlyph(white)

// Light: sunrise gradient background, white key.
renderIcon(named: "AppIcon.png", glyph: white, shadow: true) { rect in
    NSGradient(starting: amber, ending: coral)!.draw(in: rect, angle: -60)
}
// Dark: warm charcoal background, sunrise-gradient key.
renderIcon(named: "AppIcon-dark.png", glyph: gradient, shadow: false) { rect in
    charcoal.set()
    rect.fill()
}
// Tinted: grayscale glyph on transparent; iOS applies the user's tint.
renderIcon(named: "AppIcon-tinted.png", glyph: white, shadow: false, background: nil)
