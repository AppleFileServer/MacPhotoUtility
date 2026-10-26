import Foundation

/// How the screen image is dithered (PH29, PH32). The default is plain
/// Atkinson, as the specification asks; the other settings exist for the
/// comparison Jack chooses from (`mpu compare`).
public struct DitherOptions: Sendable, Hashable, Codable {
    public enum Method: String, Sendable, Hashable, Codable, CaseIterable {
        case atkinson, floydSteinberg
    }

    public var method: Method
    /// Odd rows run right to left, with the kernel mirrored.
    public var serpentine: Bool
    /// Convert the gamma-encoded grey to linear light before dithering:
    /// the share of black dots on a 1-bit screen is linear.
    public var linearTone: Bool
    /// A light unsharp mask before dithering (3 × 3 box blur, amount ½).
    public var sharpen: Bool

    public init(method: Method = .atkinson, serpentine: Bool = false,
                linearTone: Bool = false, sharpen: Bool = false) {
        self.method = method
        self.serpentine = serpentine
        self.linearTone = linearTone
        self.sharpen = sharpen
    }

    public static let standard = DitherOptions()

    /// A short description for labels: "Atkinson", "Floyd–Steinberg,
    /// serpentine, linear tone" …
    public var label: String {
        var parts = [method == .atkinson ? "Atkinson" : "Floyd–Steinberg"]
        if serpentine { parts.append("serpentine") }
        if linearTone { parts.append("linear tone") }
        if sharpen { parts.append("sharpened") }
        return parts.joined(separator: ", ")
    }
}

/// Error-diffusion dithering in integers, so the same grey image always
/// gives the same bits (PH10, PH29).
public enum Dither {
    /// Each neighbour that gets a share of the error: its offset (dx to the
    /// right, dy down) and its share in `divisor`ths.
    struct Tap { let dx: Int, dy: Int, weight: Int }

    /// Atkinson: one-eighth to each of six neighbours; the other two-eighths
    /// are dropped, which gives its crisp, contrasty look.
    static let atkinson = [Tap(dx: 1, dy: 0, weight: 1), Tap(dx: 2, dy: 0, weight: 1),
                           Tap(dx: -1, dy: 1, weight: 1), Tap(dx: 0, dy: 1, weight: 1),
                           Tap(dx: 1, dy: 1, weight: 1), Tap(dx: 0, dy: 2, weight: 1)]
    /// Floyd–Steinberg: all of the error, in sixteenths.
    static let floydSteinberg = [Tap(dx: 1, dy: 0, weight: 7), Tap(dx: -1, dy: 1, weight: 3),
                                 Tap(dx: 0, dy: 1, weight: 5), Tap(dx: 1, dy: 1, weight: 1)]

    public static func dither(_ image: GreyImage, options: DitherOptions = .standard) -> BitImage {
        var source = image
        if options.sharpen { source = sharpened(source) }
        let table = options.linearTone ? linearToneTable : identityTable
        let w = image.width, h = image.height
        var value = source.pixels.map { Int(table[Int($0)]) }

        let (taps, divisor) = options.method == .atkinson ? (atkinson, 8) : (floydSteinberg, 16)
        var out = BitImage(width: w, height: h)
        for y in 0..<h {
            let reverse = options.serpentine && y % 2 == 1
            for step in 0..<w {
                let x = reverse ? w - 1 - step : step
                let old = value[y * w + x]
                let new = old >= 128 ? 255 : 0
                if new == 0 { out[x, y] = true }
                let error = old - new
                for tap in taps {
                    let nx = x + (reverse ? -tap.dx : tap.dx), ny = y + tap.dy
                    guard nx >= 0, nx < w, ny < h else { continue }   // dropped past an edge
                    value[ny * w + nx] += error * tap.weight / divisor  // towards zero
                }
            }
        }
        return out
    }

    static let identityTable: [UInt8] = (0...255).map { UInt8($0) }

    /// Gray Gamma 2.2 to linear light, rounded: 0 → 0, 128 → 56, 255 → 255.
    public static let linearToneTable: [UInt8] = (0...255).map {
        UInt8((pow(Double($0) / 255, 2.2) * 255).rounded())
    }

    /// An unsharp mask: each pixel plus half its difference from the mean
    /// of its 3 × 3 neighbourhood (edges repeat the outermost pixels),
    /// in integers and clamped to 0…255.
    public static func sharpened(_ image: GreyImage) -> GreyImage {
        let w = image.width, h = image.height
        var out = image
        for y in 0..<h {
            for x in 0..<w {
                var sum = 0
                for dy in -1...1 {
                    let yy = min(max(y + dy, 0), h - 1)
                    for dx in -1...1 {
                        sum += Int(image[min(max(x + dx, 0), w - 1), yy])
                    }
                }
                let g = Int(image[x, y])
                out[x, y] = UInt8(min(max(g + (g - sum / 9) / 2, 0), 255))
            }
        }
        return out
    }
}
