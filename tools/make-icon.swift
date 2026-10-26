// Draws MacPhoto Utility's icon (PH84): a small greyscale print, tilted,
// behind a compact Mac whose screen shows the same picture dithered in
// 1 bit. CoreGraphics only, so it's the same every time.
//
// Usage: tools/make-icon.sh   (runs this, then makes Resources/AppIcon.icns)
//        swift tools/make-icon.swift OUT.png [SIZE]

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let out = URL(fileURLWithPath: CommandLine.arguments[1])
let size = CommandLine.arguments.count > 2 ? Int(CommandLine.arguments[2])! : 1024
let s = CGFloat(size) / 1024                       // everything is drawn on a 1024 grid

let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.scaleBy(x: s, y: s)
// Top-left origin, like the design.
ctx.translateBy(x: 0, y: 1024)
ctx.scaleBy(x: 1, y: -1)

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: a)
}

func rounded(_ r: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func shadow(_ blur: CGFloat, _ dy: CGFloat, _ alpha: CGFloat) {
    ctx.setShadow(offset: CGSize(width: 0, height: -dy * s), blur: blur * s,
                  color: CGColor(gray: 0, alpha: alpha))
}

// The scene, shared by the print and the screen: 0 black … 1 white.
func scene(_ x: Double, _ y: Double) -> Double {
    let sunD = hypot(x - 0.70, y - 0.28)
    if sunD < 0.09 { return 0.98 }
    let far = 0.52 + 0.10 * sin(x * 7.0 + 1.2) - 0.08 * (1 - abs(x - 0.45) * 2)
    let near = 0.66 + 0.07 * sin(x * 11.0 + 0.3)
    if y > near { return 0.42 + 0.25 * (y - near) / (1 - near) }          // meadow
    if y > far { return 0.22 }                                              // mountains
    return 0.88 - 0.25 * y + (sunD < 0.16 ? 0.08 : 0)                      // sky
}

// MARK: Background: the macOS rounded square

let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
ctx.saveGState()
shadow(28, 12, 0.30)
ctx.addPath(rounded(tile, 185))
ctx.setFillColor(rgb(214, 224, 233))
ctx.fillPath()
ctx.restoreGState()
ctx.saveGState()
ctx.addPath(rounded(tile, 185))
ctx.clip()
ctx.drawLinearGradient(CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  colors: [rgb(226, 234, 241), rgb(170, 186, 201)] as CFArray,
                                  locations: [0, 1])!,
                       start: CGPoint(x: 0, y: 100), end: CGPoint(x: 0, y: 924), options: [])
ctx.restoreGState()

// MARK: The print: 5:7, a white border, tilted

ctx.saveGState()
ctx.translateBy(x: 360, y: 470)
ctx.rotate(by: -0.14)
let card = CGRect(x: -185, y: -260, width: 370, height: 518)
shadow(22, 10, 0.35)
ctx.setFillColor(rgb(250, 250, 248))
ctx.fill(card)
ctx.setShadow(offset: .zero, blur: 0, color: nil)
let photo = card.insetBy(dx: 24, dy: 24)
let steps = 120
for j in 0..<steps {
    for i in 0..<steps {
        let g = scene(Double(i) / Double(steps), Double(j) / Double(steps))
        ctx.setFillColor(CGColor(gray: g, alpha: 1))
        ctx.fill(CGRect(x: photo.minX + photo.width * CGFloat(i) / CGFloat(steps),
                        y: photo.minY + photo.height * CGFloat(j) / CGFloat(steps),
                        width: photo.width / CGFloat(steps) + 0.6, height: photo.height / CGFloat(steps) + 0.6))
    }
}
ctx.restoreGState()

// MARK: The Mac: beige case, black screen, the scene in 1 bit

let body = CGRect(x: 470, y: 300, width: 400, height: 520)
ctx.saveGState()
shadow(26, 14, 0.38)
ctx.addPath(rounded(body, 34))
ctx.setFillColor(rgb(232, 226, 210))
ctx.fillPath()
ctx.restoreGState()
// The lower part, a shade darker, and the floppy slot.
ctx.saveGState()
ctx.addPath(rounded(body, 34))
ctx.clip()
ctx.setFillColor(rgb(219, 212, 194))
ctx.fill(CGRect(x: body.minX, y: 690, width: body.width, height: 130))
ctx.restoreGState()
ctx.setFillColor(rgb(120, 112, 98))
ctx.fill(CGRect(x: 690, y: 742, width: 128, height: 12))
// Bezel and screen.
let bezel = CGRect(x: 510, y: 340, width: 320, height: 300)
ctx.addPath(rounded(bezel, 22))
ctx.setFillColor(rgb(205, 198, 180))
ctx.fillPath()
let screen = CGRect(x: 538, y: 366, width: 264, height: 196)
ctx.addPath(rounded(screen, 14))
ctx.setFillColor(rgb(30, 30, 30))
ctx.fillPath()
// The scene at 66 × 46, Atkinson-dithered, each dot drawn as a square.
let dw = 66, dh = 46
var grey = [Double](repeating: 0, count: dw * dh)
for y in 0..<dh { for x in 0..<dw { grey[y * dw + x] = scene(Double(x) / Double(dw), Double(y) / Double(dh)) * 255 } }
let face = screen.insetBy(dx: 12, dy: 12)
let dot = min(face.width / CGFloat(dw), face.height / CGFloat(dh))
let origin = CGPoint(x: face.midX - dot * CGFloat(dw) / 2, y: face.midY - dot * CGFloat(dh) / 2)
ctx.setFillColor(rgb(236, 238, 232))
ctx.fill(CGRect(x: origin.x, y: origin.y, width: dot * CGFloat(dw), height: dot * CGFloat(dh)))
ctx.setFillColor(rgb(24, 24, 24))
for y in 0..<dh {
    for x in 0..<dw {
        let old = grey[y * dw + x], new = old >= 128 ? 255.0 : 0
        if new == 0 { ctx.fill(CGRect(x: origin.x + CGFloat(x) * dot, y: origin.y + CGFloat(y) * dot, width: dot, height: dot)) }
        let e = (old - new) / 8
        for (dx, dy) in [(1, 0), (2, 0), (-1, 1), (0, 1), (1, 1), (0, 2)] {
            let nx = x + dx, ny = y + dy
            if nx >= 0, nx < dw, ny < dh { grey[ny * dw + nx] += e }
        }
    }
}

let image = ctx.makeImage()!
let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote \(out.path) (\(size) × \(size))")
