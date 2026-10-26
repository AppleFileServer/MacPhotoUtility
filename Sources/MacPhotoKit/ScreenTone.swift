/// Brightness and contrast for the screen image (PH57; answers PQ9), applied
/// to the 512 × 342 grey image just before Atkinson. Never to the print.
/// In whole numbers through a 256-entry table, so the same settings always
/// give the same bits; 0 and 0 change nothing.
public struct ScreenTone: Sendable, Equatable, Hashable, Codable {
    /// −100 (darker) … 100 (lighter): shifts every grey by up to 128 levels.
    public var brightness: Int
    /// −100 (flat grey) … 100 (twice the contrast), about mid-grey.
    public var contrast: Int

    public static let range = -100...100
    public static let neutral = ScreenTone(brightness: 0, contrast: 0)

    public init(brightness: Int, contrast: Int) {
        self.brightness = min(max(brightness, Self.range.lowerBound), Self.range.upperBound)
        self.contrast = min(max(contrast, Self.range.lowerBound), Self.range.upperBound)
    }

    /// Grey in → grey out: (g − 128) × (100 + contrast) / 100 + 128 +
    /// brightness × 128 / 100, each division towards zero, then 0…255.
    public var table: [UInt8] {
        (0...255).map { g in
            let v = (g - 128) * (100 + contrast) / 100 + 128 + brightness * 128 / 100
            return UInt8(min(max(v, 0), 255))
        }
    }

    public func apply(_ image: GreyImage) -> GreyImage {
        guard self != .neutral else { return image }
        let t = table
        return GreyImage(width: image.width, height: image.height, pixels: image.pixels.map { t[Int($0)] })
    }
}
