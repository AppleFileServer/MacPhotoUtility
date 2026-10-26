import Foundation

/// File names that work on the Plus as they are (PH39): printable ASCII
/// without a colon, at most 31 characters with the extension.
public enum MacNames {
    public static let maxLength = 31

    /// A safe name from a photograph's own name: "Café: été.jpg" →
    /// "Cafe_ ete.pict". `copy` 2, 3, … adds " 2" before the extension
    /// (PH40), shortening the name if it has to.
    public static func name(for source: String, extension ext: String, copy: Int = 1) -> String {
        let stem = (source as NSString).deletingPathExtension
        let latin = stem.applyingTransform(.toLatin, reverse: false)?
            .applyingTransform(.stripDiacritics, reverse: false) ?? stem
        var safe = String(latin.unicodeScalars.map { s -> Character in
            (0x20...0x7E).contains(s.value) && s != ":" ? Character(s) : "_"
        }).trimmingCharacters(in: .whitespaces)
        if safe.hasPrefix(".") { safe = "_" + safe.dropFirst() }       // not hidden on macOS
        if safe.isEmpty { safe = "Photo" }
        let suffix = (copy > 1 ? " \(copy)" : "") + "." + ext
        let room = maxLength - suffix.count
        return String(safe.prefix(room)).trimmingCharacters(in: .whitespaces) + suffix
    }
}
