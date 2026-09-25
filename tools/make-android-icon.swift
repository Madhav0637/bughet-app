// Draws the Android app icon's foreground layer: a white rupee sign on a transparent 432x432 square.
// Android crops icons into its own shape, so the sign stays inside the central "safe zone".
// Run from the repo root:  swift tools/make-android-icon.swift
// It writes Android/app/src/main/res/drawable-nodpi/ic_launcher_foreground.png

import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 432
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

// Same rounded-bold rupee sign as the iOS icon, sized to about 55% of the visible area.
var font = CTFontCreateUIFontForLanguage(.system, 236, nil)!
let traits = [kCTFontWeightTrait: 0.4] as CFDictionary
if let base = CTFontCopyFontDescriptor(font) as CTFontDescriptor? {
    let desc = CTFontDescriptorCreateCopyWithAttributes(base, [kCTFontTraitsAttribute: traits] as CFDictionary)
    font = CTFontCreateWithFontDescriptor(desc, 236, nil)
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

let out = URL(fileURLWithPath: "Android/app/src/main/res/drawable-nodpi/ic_launcher_foreground.png")
try FileManager.default.createDirectory(at: out.deletingLastPathComponent(), withIntermediateDirectories: true)
let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
CGImageDestinationFinalize(dest)
print("Wrote \(out.path)")
