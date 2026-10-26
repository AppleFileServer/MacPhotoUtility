import Accelerate
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Why a photograph couldn't be imported, in words for the user.
public enum ImportError: Error, Equatable, CustomStringConvertible {
    case missing(String)
    case empty(String)
    case notAnImage(String)
    case unsupported(String, kind: String)
    case damaged(String, reason: String)
    case tooLarge(String, megapixels: Int)

    public var description: String {
        switch self {
        case .missing(let name): "\(name): the file isn't there."
        case .empty(let name): "\(name): the file is empty."
        case .notAnImage(let name): "\(name): not a picture this app can read."
        case .unsupported(let name, let kind):
            "\(name): a \(kind) picture. Only JPEG, HEIC, PNG and TIFF photographs are accepted."
        case .damaged(let name, let reason): "\(name): the file is damaged (\(reason))."
        case .tooLarge(let name, let mp):
            "\(name): \(mp) megapixels is more than the \(Importer.maxMegapixels) this app accepts."
        }
    }
}

/// A photograph read into memory: greyscale, the right way up (PH21–PH23).
public struct ImportedPhoto: Sendable {
    public let url: URL
    /// "JPEG", "HEIC", "PNG" or "TIFF".
    public let kind: String
    /// The size as stored, before the EXIF orientation is applied.
    public let storedWidth: Int
    public let storedHeight: Int
    /// The EXIF orientation, 1–8 (1 when the file has none).
    public let exifOrientation: Int
    /// The picture as it should be seen, in grey.
    public let image: GreyImage
}

public enum Importer {
    public static let maxMegapixels = 250

    /// The kinds accepted (PH21), recognised from the file's contents.
    static let kinds: [(UTType, String)] = [(.jpeg, "JPEG"), (.heic, "HEIC"), (.heif, "HEIF"),
                                            (.png, "PNG"), (.tiff, "TIFF")]

    /// Reads a photograph. The file is only read, never written.
    public static func load(_ url: URL) throws -> ImportedPhoto {
        let name = url.lastPathComponent
        guard let size = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? Int
        else { throw ImportError.missing(name) }
        guard size > 0 else { throw ImportError.empty(name) }

        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, options),
              let typeID = CGImageSourceGetType(source) as String?,
              CGImageSourceGetCount(source) > 0
        else { throw ImportError.notAnImage(name) }
        let type = UTType(typeID)
        guard let kind = kinds.first(where: { type?.conforms(to: $0.0) == true })?.1 else {
            throw ImportError.unsupported(name, kind: type?.localizedDescription ?? typeID)
        }
        if let reason = try truncation(url, kind: kind) { throw ImportError.damaged(name, reason: reason) }

        let index = CGImageSourceGetPrimaryImageIndex(source)
        let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any] ?? [:]
        let w = props[kCGImagePropertyPixelWidth] as? Int ?? 0
        let h = props[kCGImagePropertyPixelHeight] as? Int ?? 0
        if w * h > maxMegapixels * 1_000_000 { throw ImportError.tooLarge(name, megapixels: w * h / 1_000_000) }
        let orientation = (props[kCGImagePropertyOrientation] as? Int).flatMap { (1...8).contains($0) ? $0 : nil } ?? 1

        guard CGImageSourceGetStatusAtIndex(source, index) == .statusComplete,
              let cg = CGImageSourceCreateImageAtIndex(source, index, nil)
        else { throw ImportError.damaged(name, reason: "it can't be decoded") }

        let stored = try greyscale(cg, name: name)
        return ImportedPhoto(url: url, kind: kind, storedWidth: cg.width, storedHeight: cg.height,
                             exifOrientation: orientation, image: stored.applyingEXIF(orientation))
    }

    /// ImageIO decodes a JPEG or PNG that has been cut short without
    /// complaint, filling the rest with grey; so check each ends as it must.
    static func truncation(_ url: URL, kind: String) throws -> String? {
        guard kind == "JPEG" || kind == "PNG" else { return nil }
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let end = try handle.seekToEnd()
        try handle.seek(toOffset: end > 4096 ? end - 4096 : 0)
        var tail = [UInt8](try handle.readToEnd() ?? Data())
        if kind == "JPEG" {
            while tail.last == 0 { tail.removeLast() }          // some writers pad with zeros
            return tail.suffix(2) == [0xFF, 0xD9] ? nil : "it ends before the picture does"
        }
        let iend: [UInt8] = [0, 0, 0, 0, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82]
        return tail.suffix(12).elementsEqual(iend) ? nil : "it ends before the picture does"
    }

    /// Draws the picture as stored into 8-bit Gray Gamma 2.2 (PH9, PH22):
    /// colour management from the picture's own profile, transparency on
    /// white, no scaling.
    static func greyscale(_ cg: CGImage, name: String) throws -> GreyImage {
        let w = cg.width, h = cg.height
        var pixels = [UInt8](repeating: 255, count: w * h)
        let ok = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let ctx = CGContext(data: buffer.baseAddress, width: w, height: h,
                                      bitsPerComponent: 8, bytesPerRow: w,
                                      space: CGColorSpace(name: CGColorSpace.genericGrayGamma2_2)!,
                                      bitmapInfo: CGImageAlphaInfo.none.rawValue)
            else { return false }
            ctx.setFillColor(gray: 1, alpha: 1)
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
            ctx.interpolationQuality = .none
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard ok else { throw ImportError.damaged(name, reason: "it can't be converted to grey") }
        return GreyImage(width: w, height: h, pixels: pixels)
    }
}

// MARK: Exact turns and mirrors (PH23)

extension GreyImage {
    /// The picture as EXIF orientation `n` says it should be shown.
    public func applyingEXIF(_ n: Int) -> GreyImage {
        switch n {
        case 2: mirrored()
        case 3: turned(2)
        case 4: turned(2).mirrored()
        case 5: turned(1).mirrored()
        case 6: turned(1)
        case 7: turned(3).mirrored()
        case 8: turned(3)
        default: self
        }
    }

    /// Turned clockwise by `quarters` quarter turns, moving whole pixels.
    public func turned(_ quarters: Int) -> GreyImage {
        let q = ((quarters % 4) + 4) % 4
        guard q != 0 else { return self }
        let (ow, oh) = q == 2 ? (width, height) : (height, width)
        let constant = [0, kRotate90DegreesClockwise, kRotate180DegreesClockwise,
                        kRotate270DegreesClockwise][q]
        return vImageOperation(ow, oh) { src, dst in
            vImageRotate90_Planar8(&src, &dst, UInt8(constant), 0, vImage_Flags(kvImageNoFlags))
        }
    }

    /// Mirrored left to right.
    public func mirrored() -> GreyImage {
        vImageOperation(width, height) { src, dst in
            vImageHorizontalReflect_Planar8(&src, &dst, vImage_Flags(kvImageNoFlags))
        }
    }

    func vImageOperation(_ ow: Int, _ oh: Int,
                         _ op: (inout vImage_Buffer, inout vImage_Buffer) -> vImage_Error) -> GreyImage {
        var input = pixels
        var output = [UInt8](repeating: 0, count: ow * oh)
        input.withUnsafeMutableBytes { i in
            output.withUnsafeMutableBytes { o in
                var src = vImage_Buffer(data: i.baseAddress, height: vImagePixelCount(height),
                                        width: vImagePixelCount(width), rowBytes: width)
                var dst = vImage_Buffer(data: o.baseAddress, height: vImagePixelCount(oh),
                                        width: vImagePixelCount(ow), rowBytes: ow)
                precondition(op(&src, &dst) == kvImageNoError)
            }
        }
        return GreyImage(width: ow, height: oh, pixels: output)
    }
}
