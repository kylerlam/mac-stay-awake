import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("usage: swift generate_app_icon.swift <source.png> <output.icns>\n", stderr)
    exit(2)
}

guard let sourceImage = NSImage(contentsOfFile: CommandLine.arguments[1]) else {
    fputs("Unable to read the app icon source image\n", stderr)
    exit(1)
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
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current?.imageInterpolation = .high
    sourceImage.draw(
        in: NSRect(x: 0, y: 0, width: size, height: size),
        from: .zero,
        operation: .copy,
        fraction: 1
    )

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
    ("ic11", 32), // 16 pt at 2x
    ("icp5", 32),
    ("ic12", 64), // 32 pt at 2x
    ("ic07", 128),
    ("ic13", 256), // 128 pt at 2x
    ("ic08", 256),
    ("ic14", 512), // 256 pt at 2x
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
try icns.write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
