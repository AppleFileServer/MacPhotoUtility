import Foundation
import Testing
import zlib
@testable import MacPhotoKit

struct PackBitsTests {
    @Test func applesExample() throws {
        // Technical Note 1023's example, unpacked and packed.
        let unpacked: [UInt8] = [0xAA, 0xAA, 0xAA, 0x80, 0x00, 0x2A, 0xAA, 0xAA, 0xAA, 0xAA, 0x80, 0x00,
                                 0x2A, 0x22, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA]
        let packed: [UInt8] = [0xFE, 0xAA, 0x02, 0x80, 0x00, 0x2A, 0xFD, 0xAA, 0x03, 0x80, 0x00, 0x2A,
                               0x22, 0xF7, 0xAA]
        #expect(PackBits.pack(unpacked) == packed)
        #expect(try PackBits.unpack(packed[...], length: 24, row: 0) == unpacked)
    }

    @Test func longRunsAndLiterals() throws {
        // 300 equal bytes: 128 + 128 + 44. 200 all-different bytes: 128 + 72.
        #expect(PackBits.pack([UInt8](repeating: 7, count: 300))
                == [0x81, 7, 0x81, 7, UInt8(bitPattern: Int8(1 - 44)), 7])
        let mixed = (0..<200).map { UInt8($0 & 0xFF) }
        let p = PackBits.pack(mixed)
        #expect(p[0] == 127 && p[129] == 71 && p.count == 202)
        #expect(try PackBits.unpack(p[...], length: 200, row: 0) == mixed)
    }

    @Test func roundTripsRandomRows() throws {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<500 {
            let n = Int.random(in: 1...1300, using: &rng)
            // Few distinct values, so there are runs as well as literals.
            let row = (0..<n).map { _ in UInt8.random(in: 0...3, using: &rng) * 60 }
            #expect(try PackBits.unpack(PackBits.pack(row)[...], length: n, row: 0) == row)
        }
    }

    @Test func strictUnpacking() throws {
        #expect(throws: FormatError("row 3 unpacks to 2 bytes, not 3")) {
            try PackBits.unpack([0x01, 1, 2][...], length: 3, row: 3)
        }
        #expect(throws: FormatError("row 0 unpacks to more than 2 bytes")) {
            try PackBits.unpack([0xFE, 9][...], length: 2, row: 0)
        }
        #expect(throws: FormatError.self) { try PackBits.unpack([0x05, 1, 2][...], length: 6, row: 0) }
        #expect(throws: FormatError.self) { try PackBits.unpack([0xFE][...], length: 3, row: 0) }
        // −128 is skipped, as Apple's readers do.
        #expect(try PackBits.unpack([0x80, 0xFF, 5][...], length: 2, row: 0) == [5, 5])
    }

    @Test func crc32MatchesZlib() {
        #expect(CRC32.of(Array("123456789".utf8)) == 0xCBF4_3926)       // the standard check value
        var rng = SystemRandomNumberGenerator()
        for n in [0, 1, 750, 100_000] {
            let data = (0..<n).map { _ in UInt8.random(in: 0...255, using: &rng) }
            let z = data.withUnsafeBufferPointer { UInt32(zlib.crc32(0, $0.baseAddress, uInt($0.count))) }
            #expect(CRC32.of(data) == z)
        }
    }
}
