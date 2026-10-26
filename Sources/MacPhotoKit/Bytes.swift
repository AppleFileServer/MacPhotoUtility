/// Writing and reading big-endian fields one at a time (PH35): nothing goes
/// to disk as a Swift structure.

struct ByteWriter {
    var bytes: [UInt8] = []

    mutating func u8(_ v: UInt8) { bytes.append(v) }
    mutating func u16(_ v: Int) {
        precondition((0...0xFFFF).contains(v))
        bytes += [UInt8(v >> 8), UInt8(v & 0xFF)]
    }
    mutating func i16(_ v: Int) { u16(Int(UInt16(bitPattern: Int16(v)))) }
    mutating func u32(_ v: UInt32) {
        bytes += [UInt8(v >> 24), UInt8(v >> 16 & 0xFF), UInt8(v >> 8 & 0xFF), UInt8(v & 0xFF)]
    }
    mutating func zeros(_ n: Int) { bytes += [UInt8](repeating: 0, count: n) }
    mutating func append(_ b: [UInt8]) { bytes += b }
    /// A QuickDraw rectangle: top, left, bottom, right.
    mutating func rect(_ top: Int, _ left: Int, _ bottom: Int, _ right: Int) {
        i16(top); i16(left); i16(bottom); i16(right)
    }
    var count: Int { bytes.count }
}

/// Why a file isn't valid, in words (PH36).
public struct FormatError: Error, Equatable, CustomStringConvertible {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var description: String { message }
}

struct ByteReader {
    let bytes: [UInt8]
    private(set) var offset: Int

    init(_ bytes: [UInt8], at offset: Int = 0) {
        self.bytes = bytes
        self.offset = offset
    }

    var remaining: Int { bytes.count - offset }

    mutating func take(_ n: Int, _ what: String) throws -> ArraySlice<UInt8> {
        guard n >= 0, remaining >= n else {
            throw FormatError("the file ends at byte \(bytes.count) in the middle of \(what)")
        }
        defer { offset += n }
        return bytes[offset..<(offset + n)]
    }

    mutating func u8(_ what: String) throws -> Int { Int(try take(1, what).first!) }
    mutating func u16(_ what: String) throws -> Int {
        let b = try take(2, what)
        return Int(b[b.startIndex]) << 8 | Int(b[b.startIndex + 1])
    }
    mutating func i16(_ what: String) throws -> Int { Int(Int16(bitPattern: UInt16(try u16(what)))) }
    mutating func u32(_ what: String) throws -> UInt32 {
        UInt32(try u16(what)) << 16 | UInt32(try u16(what))
    }
    mutating func rect(_ what: String) throws -> [Int] {
        [try i16(what), try i16(what), try i16(what), try i16(what)]
    }

    /// Reads a field and checks it has the one value allowed.
    mutating func expect16(_ value: Int, _ what: String) throws {
        let v = try u16(what)
        guard v == value else { throw FormatError(String(format: "%@ is %04X, not %04X", what, v, value)) }
    }
    mutating func expect32(_ value: UInt32, _ what: String) throws {
        let v = try u32(what)
        guard v == value else { throw FormatError(String(format: "%@ is %08X, not %08X", what, v, value)) }
    }
    mutating func expectRect(_ r: [Int], _ what: String) throws {
        let v = try rect(what)
        guard v == r else { throw FormatError("\(what) is \(v), not \(r)") }
    }
    mutating func expectZeros(_ n: Int, _ what: String) throws {
        guard try take(n, what).allSatisfy({ $0 == 0 }) else { throw FormatError("\(what) isn't all zeros") }
    }
}

/// zlib's CRC-32 (IEEE 802.3, reflected, polynomial 0xEDB88320, initial and
/// final XOR 0xFFFFFFFF), as FILE_FORMATS.md §1 specifies.
public struct CRC32 {
    static let table: [UInt32] = (0..<256).map { n in
        var c = UInt32(n)
        for _ in 0..<8 { c = c & 1 != 0 ? 0xEDB8_8320 ^ (c >> 1) : c >> 1 }
        return c
    }

    private var state: UInt32 = 0xFFFF_FFFF
    public init() {}

    public mutating func update<S: Sequence>(_ bytes: S) where S.Element == UInt8 {
        for b in bytes { state = Self.table[Int((state ^ UInt32(b)) & 0xFF)] ^ (state >> 8) }
    }

    public var value: UInt32 { state ^ 0xFFFF_FFFF }

    public static func of<S: Sequence>(_ bytes: S) -> UInt32 where S.Element == UInt8 {
        var c = CRC32()
        c.update(bytes)
        return c.value
    }
}
