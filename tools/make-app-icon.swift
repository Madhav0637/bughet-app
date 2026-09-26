// Draws the Koku app icon: a mint circle, an amber pill and a periwinkle pill on graphite, 1024x1024, no transparency.
// Run from the repo root:  swift tools/make-app-icon.swift
// Then copy AppIcon.png to BudgetApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

func color(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

// Graphite background, a touch lighter at the top. iOS rounds the corners itself.
let gradient = CGGradient(colorsSpace: space, colors: [color(0x1F2937), color(0x0B1220)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])

// The mark is designed on a 512 grid (the same shapes as KokuLogo in the app). Scale it up and centre it.
let scale: CGFloat = 2.3
let markSize = CGSize(width: 258, height: 226) // x 122...380, y 122...348 on the 512 grid
let origin = CGPoint(x: (CGFloat(size) - markSize.width * scale) / 2 - 122 * scale,
                     y: (CGFloat(size) - markSize.height * scale) / 2 - 122 * scale)

/// A rect on the 512 grid (top-left origin) converted to the flipped, scaled icon canvas.
func rect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
    CGRect(x: origin.x + x * scale, y: CGFloat(size) - (origin.y + (y + height) * scale),
           width: width * scale, height: height * scale)
}

func capsule(_ r: CGRect, _ fill: CGColor) {
    let radius = min(r.width, r.height) / 2
    ctx.addPath(CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil))
    ctx.setFillColor(fill)
    ctx.fillPath()
}

capsule(rect(x: 122, y: 122, width: 144, height: 144), color(0x34D399)) // mint circle
capsule(rect(x: 122, y: 266, width: 144, height: 82), color(0xFBBF24))  // amber pill
capsule(rect(x: 266, y: 163, width: 114, height: 185), color(0x818CF8)) // periwinkle pill

let url = URL(fileURLWithPath: "AppIcon.png")
let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
CGImageDestinationFinalize(dest)
print("Wrote AppIcon.png")
