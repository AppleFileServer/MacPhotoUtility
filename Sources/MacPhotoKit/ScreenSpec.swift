/// The Macintosh Plus screen image (SPECIFICATION.md §7) and the MacPaint
/// page it is placed on (FILE_FORMATS.md §3).
public enum ScreenImage {
    public static let width = 512
    public static let height = 342
    /// Bytes in one 1-bit row: 64, already even (QuickDraw wants rowBytes even).
    public static let rowBytes = width / 8
}

public enum MacPaintPage {
    public static let width = 576
    public static let height = 720
    public static let rowBytes = width / 8          // 72
    public static let headerBytes = 512

    /// Where the screen image sits (PH12): centred on the page, both ways.
    /// x 32 is a whole number of bytes (4), so each row is copied as bytes.
    public static let screenOrigin = (x: (width - ScreenImage.width) / 2,
                                      y: (height - ScreenImage.height) / 2)   // (32, 189)
}
