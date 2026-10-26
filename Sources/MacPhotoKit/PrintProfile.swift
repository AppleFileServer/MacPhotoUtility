/// The one print size (SPECIFICATION.md §2): 2.5 × 3.5 inches, portrait
/// or landscape, at 300 PPI (the default) or 360 PPI. There is
/// deliberately no way to ask for another size.
public enum Orientation: String, Sendable, Codable, CaseIterable {
    case portrait, landscape
}

public enum PrintResolution: Int, Sendable, Codable, CaseIterable {
    case ppi300 = 300
    case ppi360 = 360

    public static let standard = PrintResolution.ppi300
    public var ppi: Int { rawValue }
}

public struct PrintProfile: Sendable, Equatable, Codable {
    /// The short and long sides in hundredths of an inch: 2.50 and 3.50.
    /// Whole numbers so every size below is exact, with no rounding.
    public static let shortSideHundredths = 250
    public static let longSideHundredths = 350

    public var orientation: Orientation
    public var resolution: PrintResolution

    public init(orientation: Orientation, resolution: PrintResolution = .standard) {
        self.orientation = orientation
        self.resolution = resolution
    }

    /// The physical size in hundredths of an inch, width first.
    public var hundredths: (width: Int, height: Int) {
        orientation == .portrait ? (Self.shortSideHundredths, Self.longSideHundredths)
                                 : (Self.longSideHundredths, Self.shortSideHundredths)
    }

    /// The output in pixels: 750 × 1050 (portrait, 300 PPI), 1050 × 750,
    /// 900 × 1260 or 1260 × 900. Both sides divide exactly.
    public var pixels: (width: Int, height: Int) {
        let h = hundredths
        return (h.width * resolution.ppi / 100, h.height * resolution.ppi / 100)
    }

    public static func == (a: PrintProfile, b: PrintProfile) -> Bool {
        a.orientation == b.orientation && a.resolution == b.resolution
    }
}
