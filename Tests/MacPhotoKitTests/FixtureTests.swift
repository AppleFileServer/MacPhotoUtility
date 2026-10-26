import CryptoKit
import Foundation
import Testing
@testable import MacPhotoKit

/// Fixtures/handoff/ (PH42) as committed: what the Transfer Utility copies.
struct FixtureTests {
    static let folder = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Fixtures/handoff")

    /// The README's table: file name → (valid, SHA-256).
    static let table: [String: (valid: Bool, sha: String)] = {
        let text = (try? String(contentsOf: folder.appendingPathComponent("README.md"), encoding: .utf8)) ?? ""
        var out = [String: (Bool, String)]()
        for line in text.split(separator: "\n") where line.hasPrefix("| `") {
            let cells = line.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            out[cells[0].trimmingCharacters(in: CharacterSet(charactersIn: "`"))] =
                (cells[2] == "yes", cells[4].trimmingCharacters(in: CharacterSet(charactersIn: "`")))
        }
        return out
    }()

    func validate(_ name: String, _ bytes: [UInt8]) throws {
        if name.hasSuffix(".MAC") { _ = try MacPaintValidator.validate(bytes) }
        else if name.contains("print") { _ = try PrintPICTValidator.validate(bytes) }
        else { _ = try ScreenPICTValidator.validate(bytes) }
    }

    @Test func everyFileIsListedAndMatches() throws {
        let names = try FileManager.default.contentsOfDirectory(atPath: Self.folder.path)
            .filter { $0 != "README.md" && !$0.hasPrefix(".") }
        #expect(names.count >= 20)
        #expect(Set(names) == Set(Self.table.keys))
        for name in names {
            let data = try Data(contentsOf: Self.folder.appendingPathComponent(name))
            let sha = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            #expect(sha == Self.table[name]?.sha, "\(name)'s SHA-256")
        }
    }

    @Test func goodPassAndBadFail() throws {
        for (name, entry) in Self.table {
            let bytes = [UInt8](try Data(contentsOf: Self.folder.appendingPathComponent(name)))
            #expect(entry.valid == !name.hasPrefix("bad-"))
            if entry.valid {
                #expect(throws: Never.self, "\(name)") { try validate(name, bytes) }
            } else {
                #expect(throws: FormatError.self, "\(name)") { try validate(name, bytes) }
            }
        }
    }
}
