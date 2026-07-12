import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("usage: swift generate_app_icon.swift <output.icns>\n", stderr)
    exit(2)
}

func renderIcon(size: Int) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw CocoaError(.fileWriteUnknown)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    let inset = CGFloat(size) * 0.05
    let iconRect = NSRect(x: inset, y: inset, width: CGFloat(size) - inset * 2, height: CGFloat(size) - inset * 2)
    let background = NSBezierPath(roundedRect: iconRect, xRadius: CGFloat(size) * 0.22, yRadius: CGFloat(size) * 0.22)
    NSColor(srgbRed: 0.72, green: 0.93, blue: 0.91, alpha: 1).setFill()
    background.fill()

    let symbolSize = CGFloat(size) * 0.52
    let configuration = NSImage.SymbolConfiguration(pointSize: symbolSize, weight: .semibold)
    let symbol = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: "Mac Stay Awake")?
        .withSymbolConfiguration(configuration)
    let symbolRect = NSRect(
        x: (CGFloat(size) - symbolSize) / 2,
        y: (CGFloat(size) - symbolSize) / 2 - CGFloat(size) * 0.015,
        width: symbolSize,
        height: symbolSize
    )
    NSColor(srgbRed: 0.08, green: 0.16, blue: 0.17, alpha: 1).set()
    symbol?.draw(in: symbolRect)
    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    return png
}

func appendBigEndian(_ value: UInt32, to data: inout Data) {
    var value = value.bigEndian
    withUnsafeBytes(of: &value) { data.append(contentsOf: $0) }
}

let iconChunks: [(type: String, pixels: Int)] = [
    ("icp4", 16),
    ("icp5", 32),
    ("icp6", 64),
    ("ic07", 128),
    ("ic08", 256),
    ("ic09", 512),
    ("ic10", 1024)
]

var chunks = Data()
for iconChunk in iconChunks {
    let png = try renderIcon(size: iconChunk.pixels)
    chunks.append(iconChunk.type.data(using: .ascii)!)
    appendBigEndian(UInt32(png.count + 8), to: &chunks)
    chunks.append(png)
}

var icns = Data("icns".utf8)
appendBigEndian(UInt32(chunks.count + 8), to: &icns)
icns.append(chunks)
try icns.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
