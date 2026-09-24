// Draws the app icon: a white rupee sign on a green gradient, 1024x1024, no transparency.
// Run from the repo root:  swift tools/make-app-icon.swift
// Then copy AppIcon.png to BudgetApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png

import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

// Green gradient, lighter at the top.
let gradient = CGGradient(colorsSpace: space, colors: [
    CGColor(srgbRed: 0.13, green: 0.77, blue: 0.47, alpha: 1),
    CGColor(srgbRed: 0.02, green: 0.47, blue: 0.33, alpha: 1),
] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])

// White rounded-bold rupee sign, centred on its glyph bounds.
var font = CTFontCreateUIFontForLanguage(.system, 830, nil)!
let traits = [kCTFontWeightTrait: 0.4] as CFDictionary
var attrs: [CFString: Any] = [kCTFontTraitsAttribute: traits]
if let base = CTFontCopyFontDescriptor(font) as CTFontDescriptor? {
    let desc = CTFontDescriptorCreateCopyWithAttributes(base, attrs as CFDictionary)
    font = CTFontCreateWithFontDescriptor(desc, 830, nil)
}
let string = NSAttributedString(string: "₹", attributes: [
    NSAttributedString.Key(kCTFontAttributeName as String): font,
    NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1),
])
let line = CTLineCreateWithAttributedString(string)
let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
ctx.textPosition = CGPoint(x: (CGFloat(size) - bounds.width) / 2 - bounds.minX,
                           y: (CGFloat(size) - bounds.height) / 2 - bounds.minY)
CTLineDraw(line, ctx)

let url = URL(fileURLWithPath: "AppIcon.png")
let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
CGImageDestinationFinalize(dest)
print("Wrote AppIcon.png")
