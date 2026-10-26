import CryptoKit
import Foundation

/// The three files the utility makes (FILE_FORMATS.md §5).
public enum OutputKind: String, Sendable, Codable, CaseIterable {
    case print, screen, macPaint

    /// The subfolder of the export folder, named as on the transfer volume (PH39).
    public var folder: String {
        switch self {
        case .print: "Print Files"
        case .screen: "PICT Files"
        case .macPaint: "MacPaint Files"
        }
    }

    public var fileExtension: String { self == .macPaint ? "MAC" : "pict" }
}

/// What to do when a file of that name is already there (PH40).
public enum IfExists: String, Sendable, CaseIterable {
    case stop, replace, keepBoth = "keep-both"
}

public enum ExportError: Error, Equatable, CustomStringConvertible {
    case exists([String])
    case invalid(OutputKind, FormatError)
    case manifestUnreadable(String)

    public var description: String {
        switch self {
        case .exists(let paths):
            "Already there, so nothing was exported: \(paths.joined(separator: ", ")). Choose to replace them or keep both."
        case let .invalid(kind, e):
            "The \(kind.rawValue) file failed its check, so nothing was exported: \(e)."
        case .manifestUnreadable(let why):
            "The folder's manifest.json can't be read (\(why)), so nothing was exported rather than overwrite it."
        }
    }
}

/// One file as exported and checked.
public struct ExportedFile: Sendable, Equatable {
    public let kind: OutputKind
    /// Relative to the export folder: "PICT Files/IMG_8691.pict".
    public let path: String
    public let bytes: Int
    public let sha256: String
}

public enum Exporter {
    /// Renders, writes, checks and records one photograph's files (PH38–PH41).
    /// Every file is written to a hidden temporary name, read back from disk
    /// and validated; only when all have passed are they renamed. A failure
    /// leaves the folder as it was.
    @discardableResult
    public static func export(_ photo: ImportedPhoto, _ c: Composition,
                              resolution: PrintResolution = .standard,
                              kinds: Set<OutputKind> = Set(OutputKind.allCases),
                              to folder: URL, ifExists: IfExists = .stop,
                              tamper: (OutputKind, inout [UInt8]) -> Void = { _, _ in }) throws
        -> (files: [ExportedFile], warnings: [RenderWarning]) {
        let fm = FileManager.default
        let order = OutputKind.allCases.filter(kinds.contains)

        // Read the manifest first, so a damaged one stops the export before anything is written.
        var manifest = try Manifest.read(from: folder)

        // The images.
        var warnings = [RenderWarning]()
        var printResult: PrintRenderer.Result?
        var screenBits: BitImage?
        if kinds.contains(.print) {
            printResult = PrintRenderer.render(photo.image, c, resolution: resolution)
            warnings += printResult!.warnings
        }
        if kinds.contains(.screen) || kinds.contains(.macPaint) {
            let s = ScreenRenderer.render(photo.image, c)
            screenBits = s.bits
            warnings += s.warnings
        }

        // The names: stop before writing anything if one is taken.
        var targets = [OutputKind: URL]()
        var taken = [String]()
        for kind in order {
            let dir = folder.appendingPathComponent(kind.folder)
            var copy = 1
            var url = dir.appendingPathComponent(MacNames.name(for: photo.url.lastPathComponent,
                                                               extension: kind.fileExtension))
            if fm.fileExists(atPath: url.path) {
                switch ifExists {
                case .stop: taken.append("\(kind.folder)/\(url.lastPathComponent)")
                case .replace: break
                case .keepBoth:
                    repeat {
                        copy += 1
                        url = dir.appendingPathComponent(MacNames.name(for: photo.url.lastPathComponent,
                                                                       extension: kind.fileExtension, copy: copy))
                    } while fm.fileExists(atPath: url.path)
                }
            }
            targets[kind] = url
        }
        guard taken.isEmpty else { throw ExportError.exists(taken) }

        // Write each to a temporary name, read it back, check it.
        var temps = [OutputKind: URL]()
        func removeTemps() { for t in temps.values { try? fm.removeItem(at: t) } }
        do {
            for kind in order {
                var bytes: [UInt8]
                switch kind {
                case .print: bytes = PrintPICTWriter.write(printResult!.image, profile: printResult!.profile)
                case .screen: bytes = ScreenPICTWriter.write(screenBits!)
                case .macPaint: bytes = MacPaintWriter.write(screenBits!)
                }
                tamper(kind, &bytes)
                let dir = targets[kind]!.deletingLastPathComponent()
                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                let temp = dir.appendingPathComponent(".mpu-\(UUID().uuidString).tmp")
                temps[kind] = temp
                try Data(bytes).write(to: temp)
                let onDisk = [UInt8](try Data(contentsOf: temp))
                do {
                    switch kind {
                    case .print:
                        guard try PrintPICTValidator.validate(onDisk).image == printResult!.image
                        else { throw FormatError("it reads back as a different picture") }
                    case .screen:
                        guard try ScreenPICTValidator.validate(onDisk) == screenBits!
                        else { throw FormatError("it reads back as a different picture") }
                    case .macPaint:
                        guard try MacPaintValidator.validate(onDisk) == screenBits!
                        else { throw FormatError("it reads back as a different picture") }
                    }
                } catch let e as FormatError { throw ExportError.invalid(kind, e) }
            }
        } catch {
            removeTemps()
            throw error
        }

        // All passed: rename them into place, then record them.
        var files = [ExportedFile]()
        let source = try Manifest.Source(photo.url)
        for kind in order {
            let target = targets[kind]!, temp = temps[kind]!
            let data = try Data(contentsOf: temp)
            if fm.fileExists(atPath: target.path) {
                _ = try fm.replaceItemAt(target, withItemAt: temp)
            } else {
                try fm.moveItem(at: temp, to: target)
            }
            let file = ExportedFile(kind: kind, path: "\(kind.folder)/\(target.lastPathComponent)",
                                    bytes: data.count, sha256: Manifest.sha256(data))
            files.append(file)
            let size = kind == .print ? printResult!.image : nil
            manifest.record(file, width: size?.width ?? ScreenImage.width,
                            height: size?.height ?? ScreenImage.height,
                            source: source, composition: c,
                            ppi: kind == .print ? resolution.ppi : nil,
                            warnings: warnings.filter { w in
                                if case .smallForPrint = w { return kind == .print }
                                return kind != .print
                            }.map(\.description))
        }
        try manifest.write(to: folder)
        return (files, warnings)
    }
}

/// `manifest.json` (FILE_FORMATS.md §4; PH41): a record of every file
/// exported into the folder, for Jack; the Plus never sees it.
public struct Manifest: Codable, Equatable {
    public struct Source: Codable, Equatable {
        public let path: String
        public let bytes: Int
        public let sha256: String

        init(_ url: URL) throws {
            let data = try Data(contentsOf: url)
            path = url.path
            bytes = data.count
            sha256 = Manifest.sha256(data)
        }
    }

    public struct Entry: Codable, Equatable {
        public let path: String
        public let kind: OutputKind
        public let bytes: Int
        public let sha256: String
        public let width: Int
        public let height: Int
        public let validation: String
        public let exported: String
        public let appVersion: String
        public let source: Source
        public let composition: Composition
        public let ppi: Int?
        public let warnings: [String]
    }

    public var manifestVersion = 1
    public var files: [Entry] = []

    static let name = "manifest.json"

    static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    public static func read(from folder: URL) throws -> Manifest {
        let url = folder.appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: url.path) else { return Manifest() }
        do {
            let m = try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: url))
            guard m.manifestVersion == 1 else { throw ExportError.manifestUnreadable("version \(m.manifestVersion)") }
            return m
        } catch let e as ExportError { throw e } catch {
            throw ExportError.manifestUnreadable("\(error.localizedDescription)")
        }
    }

    mutating func record(_ f: ExportedFile, width: Int, height: Int, source: Source,
                         composition: Composition, ppi: Int?, warnings: [String]) {
        files.removeAll { $0.path == f.path }
        files.append(Entry(path: f.path, kind: f.kind, bytes: f.bytes, sha256: f.sha256,
                           width: width, height: height, validation: "passed",
                           exported: ISO8601DateFormatter().string(from: Date()),
                           appVersion: AppVersion.string, source: source, composition: composition,
                           ppi: ppi, warnings: warnings))
        files.sort { $0.path < $1.path }
    }

    /// Written to a temporary name and renamed, like the pictures.
    func write(to folder: URL) throws {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let url = folder.appendingPathComponent(Self.name)
        let temp = folder.appendingPathComponent(".mpu-\(UUID().uuidString).tmp")
        try enc.encode(self).write(to: temp)
        if FileManager.default.fileExists(atPath: url.path) {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: temp)
        } else {
            try FileManager.default.moveItem(at: temp, to: url)
        }
    }
}
