import Accelerate

/// A warning on a rendered image: the crop has fewer source pixels than
/// the output, so it was enlarged (PH14, PH30). It still renders.
public enum RenderWarning: Sendable, Equatable, CustomStringConvertible {
    case smallForPrint(source: PixelRect, needed: (width: Int, height: Int))
    case smallForScreen(source: PixelRect)

    public static func == (a: RenderWarning, b: RenderWarning) -> Bool {
        switch (a, b) {
        case let (.smallForPrint(s1, n1), .smallForPrint(s2, n2)): s1 == s2 && n1 == n2
        case let (.smallForScreen(s1), .smallForScreen(s2)): s1 == s2
        default: false
        }
    }

    public var description: String {
        switch self {
        case let .smallForPrint(s, n):
            "The print crop is \(s.width) × \(s.height) photo pixels but the print needs \(n.width) × \(n.height): it will be enlarged and may look soft."
        case let .smallForScreen(s):
            "The screen crop is \(s.width) × \(s.height) photo pixels, less than the screen's 512 × 342: it will be enlarged."
        }
    }
}

/// The print image (specification §6; PH28): the print crop, resampled to
/// exactly the profile's size, 8-bit grey. Never dithered.
public enum PrintRenderer {
    public struct Result: Sendable {
        public let image: GreyImage
        public let profile: PrintProfile
        /// The crop, in pixels of the turned photograph.
        public let source: PixelRect
        public let warnings: [RenderWarning]
    }

    public static func render(_ upright: GreyImage, _ c: Composition,
                              resolution: PrintResolution = .standard) -> Result {
        let profile = PrintProfile(orientation: c.orientation, resolution: resolution)
        let size = profile.pixels
        let rect = c.printRect(uprightWidth: upright.width, height: upright.height)
        let image = Resampler.region(upright, turns: c.quarterTurns, rect: rect, to: size.width, size.height)
        let small = rect.width < size.width || rect.height < size.height
        return Result(image: image, profile: profile, source: rect,
                      warnings: small ? [.smallForPrint(source: rect, needed: size)] : [])
    }
}

/// The screen image (specification §7; PH28, PH29): the screen crop,
/// resampled to 512 × 342 grey, then dithered. Made from the photograph,
/// never from the print image.
public enum ScreenRenderer {
    public struct Result: Sendable {
        /// The 512 × 342 grey image that was dithered (after the screen tone).
        public let grey: GreyImage
        public let bits: BitImage
        public let source: PixelRect
        public let warnings: [RenderWarning]
    }

    public static func render(_ upright: GreyImage, _ c: Composition,
                              dither: DitherOptions = .standard) -> Result {
        let rect = c.screenRect(uprightWidth: upright.width, height: upright.height)
        let resampled = Resampler.region(upright, turns: c.quarterTurns, rect: rect,
                                         to: ScreenImage.width, ScreenImage.height)
        let grey = c.screenTone.apply(resampled)                // PH57; neutral changes nothing
        let small = rect.width < ScreenImage.width || rect.height < ScreenImage.height
        return Result(grey: grey, bits: Dither.dither(grey, options: dither), source: rect,
                      warnings: small ? [.smallForScreen(source: rect)] : [])
    }
}

/// Cropping, turning and resampling, shared by both renderers: the only
/// thing they have in common (ARCHITECTURE.md).
public enum Resampler {
    /// The pixels of `rect` (in the turned photograph), turned, then
    /// resampled to exactly `w` × `h` with vImage's high-quality (Lanczos)
    /// scaling (PH10). Only the crop is turned, not the whole photograph.
    public static func region(_ upright: GreyImage, turns: Int, rect: PixelRect,
                              to w: Int, _ h: Int) -> GreyImage {
        let turned = turns % 2 == 0 ? (upright.width, upright.height) : (upright.height, upright.width)
        let back = rect.unturned(turns, turnedWidth: turned.0, turnedHeight: turned.1)
        return scaled(upright.cropped(back).turned(turns), to: w, h)
    }

    /// The editor's working copy (PH49): no more than `maxSide` pixels on
    /// its long side, the shape kept. Never used for an output.
    public static func reduced(_ image: GreyImage, maxSide: Int = 2000) -> GreyImage {
        let long = max(image.width, image.height)
        guard long > maxSide else { return image }
        let w = max(1, (image.width * maxSide + long / 2) / long)
        let h = max(1, (image.height * maxSide + long / 2) / long)
        return scaled(image, to: w, h)
    }

    public static func scaled(_ image: GreyImage, to w: Int, _ h: Int) -> GreyImage {
        if image.width == w && image.height == h { return image }
        return image.vImageOperation(w, h) { src, dst in
            vImageScale_Planar8(&src, &dst, nil, vImage_Flags(kvImageHighQualityResampling))
        }
    }
}
