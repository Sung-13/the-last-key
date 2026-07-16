import AppKit

// Painterly "K" icon: layered paint-stroke bands (Werner Bronkhorst-inspired)
// in the Dawn Warm palette, with a bold rounded K on top.
// Usage: swift tools/make_icon.swift <path-to-AppIcon.appiconset>

// MARK: - Deterministic RNG (SplitMix64) so every run yields identical PNGs.

struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

var rng = SeededRNG(state: 0x4441_574E) // "DAWN"

func jitter(_ range: ClosedRange<CGFloat>) -> CGFloat {
    CGFloat.random(in: range, using: &rng)
}

// MARK: - Colors

func hexColor(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1)
}

func blend(_ a: NSColor, toward b: NSColor, fraction f: CGFloat) -> NSColor {
    let c1 = a.usingColorSpace(.sRGB)!, c2 = b.usingColorSpace(.sRGB)!
    return NSColor(srgbRed: c1.redComponent + (c2.redComponent - c1.redComponent) * f,
                   green: c1.greenComponent + (c2.greenComponent - c1.greenComponent) * f,
                   blue: c1.blueComponent + (c2.blueComponent - c1.blueComponent) * f,
                   alpha: 1)
}

func luminance(_ c: NSColor) -> CGFloat {
    let s = c.usingColorSpace(.sRGB)!
    return 0.2126 * s.redComponent + 0.7152 * s.greenComponent + 0.0722 * s.blueComponent
}

let cream = hexColor(0xFBF6EE)
let charcoal = hexColor(0x1C1917)

// Sunrise ramp, sky (top strip = cream base) down to deep brick coral.
let lightBandColors: [NSColor] = [
    0xFDE68A, // pale amber
    0xFBBF24, // golden
    0xF59E0B, // amber
    0xEF8036, // orange bridge
    0xF4715F, // coral
    0xDE5643, // deep coral
    0xC2432F, // brick
].map(hexColor)

// Embers-at-night ramp for the dark variant — same hue journey, hand-picked
// rich darks (blending the light ramp toward charcoal goes muddy olive).
let darkBandColors: [NSColor] = [
    0x94700E, // dark gold
    0xB8860B, // goldenrod
    0xC26D08, // burnt amber
    0xA84E17, // burnt orange
    0xB2412F, // ember coral
    0x8E3220, // deep ember
    0x6E2417, // darkest brick
].map(hexColor)

// MARK: - Band geometry (generated once; all three variants share it)

let px: CGFloat = 1024

// 7 overlapping full-height bands; each exposes a wavy top-edge strip of the
// band behind it. Jitter budget keeps adjacent edges from ever crossing.
let bandEdges: [[CGPoint]] = (1...7).map { i in
    let baseY = px * (1 - CGFloat(i) / 8)
    let bandOffset = jitter(-16...16)
    let freq = 1.2 + jitter(0...0.9)
    let phase = jitter(0...(2 * .pi))
    let amp = 10 + jitter(0...10)
    return stride(from: CGFloat(-40), through: px + 40, by: 92).map { x in
        CGPoint(x: x,
                y: baseY + bandOffset + jitter(-14...14)
                    + amp * sin(x / px * .pi * freq + phase))
    }
}

/// Open path along a band's wavy top edge (smooth horizontal-handle curves).
func edgePath(_ pts: [CGPoint]) -> NSBezierPath {
    let p = NSBezierPath()
    p.move(to: pts[0])
    for j in 1..<pts.count {
        let prev = pts[j - 1], cur = pts[j]
        let dx = (cur.x - prev.x) / 3
        p.curve(to: cur,
                controlPoint1: CGPoint(x: prev.x + dx, y: prev.y),
                controlPoint2: CGPoint(x: cur.x - dx, y: cur.y))
    }
    return p
}

/// Closed band: wavy top edge, extending past the canvas bottom.
func bandPath(_ pts: [CGPoint]) -> NSBezierPath {
    let p = edgePath(pts)
    p.line(to: CGPoint(x: px + 40, y: -40))
    p.line(to: CGPoint(x: -40, y: -40))
    p.close()
    return p
}

let bandPaths = bandEdges.map(bandPath)
let highlightPaths = bandEdges.map(edgePath)

// MARK: - K glyph path (CoreText outline, scaled + optically centered)

func kGlyphPath() -> NSBezierPath {
    let base = NSFont.systemFont(ofSize: 600, weight: .black)
    let desc = base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor
    let font = NSFont(descriptor: desc, size: 600) ?? base
    var glyph = CGGlyph(0)
    var chars: [UniChar] = Array("K".utf16)
    guard CTFontGetGlyphsForCharacters(font, &chars, &glyph, 1),
          let cgPath = CTFontCreatePathForGlyph(font, glyph, nil) else {
        fatalError("could not build K glyph path")
    }
    let path = NSBezierPath(cgPath: cgPath)

    let bounds = path.bounds
    let scale = 520 / max(bounds.width, bounds.height)
    var transform = AffineTransform()
    transform.translate(x: 512, y: 496) // optical center, nudged below true center
    transform.scale(scale)
    transform.translate(x: -bounds.midX, y: -bounds.midY)
    path.transform(using: transform)
    return path
}

let kPath = kGlyphPath()

// MARK: - Rendering

enum Variant { case light, dark, tinted }

func draw(_ variant: Variant, in rect: NSRect) {
    let ctx = NSGraphicsContext.current!.cgContext

    switch variant {
    case .light, .dark:
        let isDark = variant == .dark
        (isDark ? charcoal : cream).set()
        rect.fill()

        let colors = isDark ? darkBandColors : lightBandColors
        for (i, band) in bandPaths.enumerated() {
            NSGraphicsContext.current!.saveGraphicsState()
            let shadow = NSShadow()
            shadow.shadowColor = NSColor.black.withAlphaComponent(isDark ? 0.30 : 0.16)
            shadow.shadowBlurRadius = 10
            shadow.shadowOffset = NSSize(width: 0, height: 7) // cast onto the band behind
            shadow.set()
            colors[i].set()
            band.fill()
            NSGraphicsContext.current!.restoreGraphicsState()

            // Highlight ridge along the wavy edge — suggests paint thickness.
            blend(colors[i], toward: .white, fraction: isDark ? 0.12 : 0.25).set()
            let ridge = highlightPaths[i]
            ridge.lineWidth = 3
            ridge.stroke()
        }

        NSGraphicsContext.current!.saveGraphicsState()
        let kShadow = NSShadow()
        kShadow.shadowColor = NSColor.black.withAlphaComponent(0.30)
        kShadow.shadowBlurRadius = 22
        kShadow.shadowOffset = NSSize(width: 0, height: -10)
        kShadow.set()
        NSColor.white.set()
        kPath.fill()
        NSGraphicsContext.current!.restoreGraphicsState()

    case .tinted:
        // Apple spec: monochrome on transparent. White bands at luminance-mapped
        // alpha, drawn with .copy so overlaps replace instead of accumulate.
        for (i, band) in bandPaths.enumerated() {
            let lum = luminance(lightBandColors[i])
            let alpha = 0.25 + 0.6 * min(max((lum - 0.2) / 0.75, 0), 1)
            ctx.saveGState()
            ctx.setBlendMode(.copy)
            ctx.addPath(band.cgPath)
            ctx.setFillColor(CGColor(gray: 1, alpha: alpha))
            ctx.fillPath()
            ctx.restoreGState()
        }
        NSColor.white.set()
        kPath.fill()
    }
}

func renderIcon(named name: String, variant: Variant) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(px), pixelsHigh: Int(px),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .calibratedRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: px, height: px)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    draw(variant, in: NSRect(x: 0, y: 0, width: px, height: px))

    NSGraphicsContext.restoreGraphicsState()
    let png = rep.representation(using: .png, properties: [:])!
    let out = CommandLine.arguments[1] + "/" + name
    try! png.write(to: URL(fileURLWithPath: out))
    print("wrote \(out)")
}

renderIcon(named: "AppIcon.png", variant: .light)
renderIcon(named: "AppIcon-dark.png", variant: .dark)
renderIcon(named: "AppIcon-tinted.png", variant: .tinted)
