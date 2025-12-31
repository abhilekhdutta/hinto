#!/usr/bin/env swift

import Cocoa

// SF Symbol name for the icon
let symbolName = "cursorarrow.rays"

// Icon sizes needed for macOS app
let sizes: [(size: Int, scale: Int, filename: String)] = [
    (16, 1, "icon_16x16.png"),
    (16, 2, "icon_16x16@2x.png"),
    (32, 1, "icon_32x32.png"),
    (32, 2, "icon_32x32@2x.png"),
    (128, 1, "icon_128x128.png"),
    (128, 2, "icon_128x128@2x.png"),
    (256, 1, "icon_256x256.png"),
    (256, 2, "icon_256x256@2x.png"),
    (512, 1, "icon_512x512.png"),
    (512, 2, "icon_512x512@2x.png"),
]

func generateIcon(symbolName: String, size: Int, scale: Int) -> NSImage? {
    let pixelSize = size * scale
    let config = NSImage.SymbolConfiguration(pointSize: CGFloat(pixelSize) * 0.6, weight: .medium)

    guard let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
        .withSymbolConfiguration(config)
    else {
        print("Failed to load symbol: \(symbolName)")
        return nil
    }

    // Create image with gradient background
    let image = NSImage(size: NSSize(width: pixelSize, height: pixelSize))
    image.lockFocus()

    // Draw rounded rect background with gradient
    let rect = NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize)
    let cornerRadius = CGFloat(pixelSize) * 0.22 // macOS icon corner radius
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

    // Gradient background (blue to purple)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0),
        NSColor(red: 0.6, green: 0.4, blue: 0.9, alpha: 1.0),
    ])
    gradient?.draw(in: path, angle: -45)

    // Draw symbol centered
    let symbolSize = symbol.size
    let x = (CGFloat(pixelSize) - symbolSize.width) / 2
    let y = (CGFloat(pixelSize) - symbolSize.height) / 2

    // Draw white symbol
    let tintedSymbol = symbol.copy() as! NSImage
    tintedSymbol.lockFocus()
    NSColor.white.set()
    NSRect(origin: .zero, size: symbolSize).fill(using: .sourceAtop)
    tintedSymbol.unlockFocus()

    tintedSymbol.draw(at: NSPoint(x: x, y: y), from: .zero, operation: .sourceOver, fraction: 1.0)

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to path: String) -> Bool {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        return false
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        return true
    } catch {
        print("Failed to write: \(error)")
        return false
    }
}

// Get output directory
let scriptPath = CommandLine.arguments[0]
let scriptDir = (scriptPath as NSString).deletingLastPathComponent
let outputDir = (scriptDir as NSString).appendingPathComponent("../Resources/Assets.xcassets/AppIcon.appiconset")

print("Generating icons to: \(outputDir)")

// Generate all sizes
for (size, scale, filename) in sizes {
    if let image = generateIcon(symbolName: symbolName, size: size, scale: scale) {
        let path = (outputDir as NSString).appendingPathComponent(filename)
        if savePNG(image, to: path) {
            print("Created: \(filename) (\(size * scale)x\(size * scale))")
        }
    }
}

// Update Contents.json
let contentsJson = """
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

let contentsPath = (outputDir as NSString).appendingPathComponent("Contents.json")
try? contentsJson.write(toFile: contentsPath, atomically: true, encoding: .utf8)
print("Updated: Contents.json")
print("Done!")
