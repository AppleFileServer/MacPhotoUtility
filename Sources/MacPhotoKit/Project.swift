import CryptoKit
import Foundation

/// A photograph's size and SHA-256: how a project tells the same photograph,
/// moved, from a different one (PH73, PH75).
public struct Fingerprint: Sendable, Equatable, Codable {
    public let bytes: Int
    public let sha256: String

    public init(bytes: Int, sha256: String) {
        self.bytes = bytes
        self.sha256 = sha256
    }

    /// Reads the whole file in 1 MB pieces; never writes it.
    public static func of(_ url: URL) throws -> Fingerprint {
        let h = try FileHandle(forReadingFrom: url)
        defer { try? h.close() }
        var hash = SHA256()
        var total = 0
        while let chunk = try h.read(upToCount: 1 << 20), !chunk.isEmpty {
            hash.update(data: chunk)
            total += chunk.count
        }
        return Fingerprint(bytes: total, sha256: hash.finalize().map { String(format: "%02x", $0) }.joined())
    }

    /// Quick first test: the file's size, from the file system.
    public static func size(_ url: URL) -> Int? {
        (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? Int
    }
}

/// One export of one photograph, kept in its history (PH76).
public struct ExportRecord: Sendable, Equatable, Codable {
    public struct File: Sendable, Equatable, Codable {
        public let path: String
        public let bytes: Int
        public let sha256: String
    }
    public let date: String
    public let folder: String
    public let files: [File]
    public let ppi: Int?
    public let warnings: [String]
    public let appVersion: String

    public init(folder: URL, files: [ExportedFile], ppi: Int?, warnings: [String], date: Date = Date()) {
        self.date = ISO8601DateFormatter().string(from: date)
        self.folder = folder.path
        self.files = files.map { File(path: $0.path, bytes: $0.bytes, sha256: $0.sha256) }
        self.ppi = ppi
        self.warnings = warnings
        appVersion = AppVersion.string
    }
}

/// The project file, `Name.macphoto` (FILE_FORMATS.md §6; PH70). JSON for
/// this Mac only; it never holds the photographs, only where they are.
public struct ProjectFile: Sendable, Equatable, Codable {
    public static let currentVersion = 1
    public static let fileExtension = "macphoto"

    public struct Settings: Sendable, Equatable, Codable {
        public var ppi: Int
        public var outputs: [String]
        public var destination: String?
    }

    public struct Photograph: Sendable, Equatable, Codable {
        public var path: String
        /// A Finder bookmark, which follows the file if it's moved or renamed.
        public var bookmark: Data?
        public var fingerprint: Fingerprint?
        public var kind: String?
        public var uprightWidth: Int
        public var uprightHeight: Int
        public var composition: Composition?
        public var seen: Bool
        public var exported: Bool
        public var changedSinceExport: Bool
        /// Why it couldn't be read, if it couldn't (PH77).
        public var problem: String?
        /// Relinked to a file whose content differs, on purpose (PH74).
        public var acceptedDifferentFile: Bool
        public var history: [ExportRecord]
    }

    public var projectVersion = ProjectFile.currentVersion
    public var appVersion = AppVersion.string
    public var created: String
    public var modified: String
    public var settings: Settings
    public var photographs: [Photograph]

    public enum Problem: Error, Equatable, CustomStringConvertible {
        case unreadable(String)
        case newer(Int)

        public var description: String {
            switch self {
            case .unreadable(let why): "The project can't be read: \(why)."
            case .newer(let v):
                "The project was saved by a newer MacPhoto Utility (project version \(v)); this one reads version \(ProjectFile.currentVersion). Nothing was changed."
            }
        }
    }

    public func encoded() throws -> Data {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try e.encode(self)
    }

    /// Reads a project; a newer version is refused before anything else
    /// is read (PH79). Unknown fields are ignored.
    public static func decode(_ data: Data) throws -> ProjectFile {
        struct VersionOnly: Decodable { let projectVersion: Int }
        let version: Int
        do { version = try JSONDecoder().decode(VersionOnly.self, from: data).projectVersion }
        catch { throw Problem.unreadable("it isn't a MacPhoto project") }
        guard version <= currentVersion else { throw Problem.newer(version) }
        do { return try JSONDecoder().decode(ProjectFile.self, from: data) }
        catch let DecodingError.keyNotFound(key, _) { throw Problem.unreadable("\(key.stringValue) is missing") }
        catch let DecodingError.typeMismatch(_, c) { throw Problem.unreadable("\(c.codingPath.map(\.stringValue).joined(separator: ".")) is the wrong kind of value") }
        catch { throw Problem.unreadable("it's damaged") }
    }

    /// Writes to a temporary name beside it, then renames (PH72).
    public func write(to url: URL) throws {
        let temp = url.deletingLastPathComponent().appendingPathComponent(".mpu-\(UUID().uuidString).tmp")
        try encoded().write(to: temp)
        if FileManager.default.fileExists(atPath: url.path) {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: temp)
        } else {
            try FileManager.default.moveItem(at: temp, to: url)
        }
    }
}
