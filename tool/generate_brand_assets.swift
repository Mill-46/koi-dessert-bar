import AppKit
import Foundation

let fileManager = FileManager.default
let root = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let brandingDir = root.appendingPathComponent("assets/branding", isDirectory: true)

try fileManager.createDirectory(at: brandingDir, withIntermediateDirectories: true)

let cream = NSColor(
    calibratedRed: 242.0 / 255.0,
    green: 240.0 / 255.0,
    blue: 235.0 / 255.0,
    alpha: 1
)
let green = NSColor(
    calibratedRed: 0.0 / 255.0,
    green: 98.0 / 255.0,
    blue: 65.0 / 255.0,
    alpha: 1
)
let darkGreen = NSColor(
    calibratedRed: 30.0 / 255.0,
    green: 57.0 / 255.0,
    blue: 50.0 / 255.0,
    alpha: 1
)
let gold = NSColor(
    calibratedRed: 211.0 / 255.0,
    green: 166.0 / 255.0,
    blue: 74.0 / 255.0,
    alpha: 1
)

func font(named name: String, size: CGFloat, weight: NSFont.Weight = .bold) -> NSFont {
    return NSFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight)
}

func pngData(from image: NSImage) -> Data? {
    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData)
    else {
        return nil
    }

    return bitmap.representation(using: .png, properties: [:])
}

func save(_ image: NSImage, to relativePath: String) throws {
    let url = root.appendingPathComponent(relativePath)
    try fileManager.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    guard let data = pngData(from: image) else {
        throw NSError(domain: "asset-gen", code: 1)
    }
    try data.write(to: url)
}

func drawIcon(size: CGFloat, includeWordmark: Bool) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let bounds = NSRect(x: 0, y: 0, width: size, height: size)
    cream.setFill()
    bounds.fill()

    let tileSide = size * (includeWordmark ? 0.42 : 0.74)
    let tileOriginY = includeWordmark ? size * 0.43 : size * 0.13
    let tileRect = NSRect(
        x: (size - tileSide) / 2,
        y: tileOriginY,
        width: tileSide,
        height: tileSide
    )

    let shadow = NSShadow()
    shadow.shadowColor = darkGreen.withAlphaComponent(0.14)
    shadow.shadowBlurRadius = size * 0.03
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.01)
    shadow.set()

    let tile = NSBezierPath(
        roundedRect: tileRect,
        xRadius: tileSide * 0.23,
        yRadius: tileSide * 0.23
    )
    green.setFill()
    tile.fill()

    NSGraphicsContext.current?.saveGraphicsState()
    tile.addClip()

    let accentRect = NSRect(
        x: tileRect.maxX - tileSide * 0.28,
        y: tileRect.maxY - tileSide * 0.24,
        width: tileSide * 0.26,
        height: tileSide * 0.2
    )
    let accent = NSBezierPath(ovalIn: accentRect)
    gold.setFill()
    accent.fill()

    let wave = NSBezierPath()
    wave.move(to: NSPoint(x: tileRect.minX + tileSide * 0.16, y: tileRect.minY + tileSide * 0.25))
    wave.curve(
        to: NSPoint(x: tileRect.maxX - tileSide * 0.12, y: tileRect.minY + tileSide * 0.15),
        controlPoint1: NSPoint(x: tileRect.minX + tileSide * 0.35, y: tileRect.minY + tileSide * 0.11),
        controlPoint2: NSPoint(x: tileRect.minX + tileSide * 0.62, y: tileRect.minY + tileSide * 0.31)
    )
    wave.lineWidth = tileSide * 0.05
    cream.withAlphaComponent(0.9).setStroke()
    wave.stroke()
    NSGraphicsContext.current?.restoreGraphicsState()

    let letter = "K"
    let letterAttributes: [NSAttributedString.Key: Any] = [
        .font: font(named: "Didot-Bold", size: tileSide * 0.58),
        .foregroundColor: NSColor.white
    ]
    let letterSize = letter.size(withAttributes: letterAttributes)
    let letterPoint = NSPoint(
        x: tileRect.midX - letterSize.width / 2,
        y: tileRect.midY - letterSize.height / 2 - tileSide * 0.05
    )
    letter.draw(at: letterPoint, withAttributes: letterAttributes)

    if includeWordmark {
        let topAttrs: [NSAttributedString.Key: Any] = [
            .font: font(named: "AvenirNext-DemiBold", size: size * 0.052, weight: .semibold),
            .foregroundColor: darkGreen
        ]
        let bottomAttrs: [NSAttributedString.Key: Any] = [
            .font: font(named: "AvenirNext-Medium", size: size * 0.028, weight: .medium),
            .foregroundColor: darkGreen.withAlphaComponent(0.78)
        ]
        let topText = "KOI"
        let bottomText = "DESSERT BAR"
        let topSize = topText.size(withAttributes: topAttrs)
        let bottomSize = bottomText.size(withAttributes: bottomAttrs)
        topText.draw(
            at: NSPoint(x: (size - topSize.width) / 2, y: size * 0.22),
            withAttributes: topAttrs
        )
        bottomText.draw(
            at: NSPoint(x: (size - bottomSize.width) / 2, y: size * 0.17),
            withAttributes: bottomAttrs
        )
    }

    image.unlockFocus()
    return image
}

try save(drawIcon(size: 1024, includeWordmark: false), to: "assets/branding/app-icon-master.png")
try save(drawIcon(size: 2048, includeWordmark: true), to: "assets/branding/splash-master.png")
