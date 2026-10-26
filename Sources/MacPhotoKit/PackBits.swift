/// Apple's PackBits (Inside Macintosh I; Technical Note 1023), one row at a
/// time (PH34). Each run starts with a count byte n:
/// - 0…127: the next n + 1 bytes are literal;
/// - −1…−127: the next byte is repeated 1 − n times;
/// - −128: nothing (Apple's readers skip it; the encoder never writes it).
public enum PackBits {
    /// Packs one row. Runs of 3 or more equal bytes become repeats, the rest
    /// literals; no run is longer than 128 bytes.
    public static func pack<C: Collection>(_ row: C) -> [UInt8] where C.Element == UInt8, C.Index == Int {
        var out = [UInt8]()
        out.reserveCapacity(row.count + row.count / 128 + 1)
        var i = row.startIndex
        let end = row.endIndex

        func runLength(at p: Int) -> Int {
            var n = 1
            while p + n < end, n < 128, row[p + n] == row[p] { n += 1 }
            return n
        }

        while i < end {
            let run = runLength(at: i)
            if run >= 3 {
                out.append(UInt8(bitPattern: Int8(1 - run)))
                out.append(row[i])
                i += run
            } else {
                let start = i
                while i < end, i - start < 128, runLength(at: i) < 3 { i += 1 }
                out.append(UInt8(i - start - 1))
                out.append(contentsOf: row[start..<i])
            }
        }
        return out
    }

    /// Unpacks exactly one row of `length` bytes from `packed`, which must
    /// be used up exactly. Anything else is an error, as it is to MacPaint.
    public static func unpack(_ packed: ArraySlice<UInt8>, length: Int, row: Int) throws -> [UInt8] {
        var out = [UInt8]()
        out.reserveCapacity(length)
        var i = packed.startIndex
        while i < packed.endIndex {
            let n = Int(Int8(bitPattern: packed[i]))
            i += 1
            if n >= 0 {
                guard i + n + 1 <= packed.endIndex else { throw FormatError("row \(row): a literal run goes past the row's data") }
                out.append(contentsOf: packed[i..<(i + n + 1)])
                i += n + 1
            } else if n != -128 {
                guard i < packed.endIndex else { throw FormatError("row \(row): a repeat has no byte to repeat") }
                out.append(contentsOf: repeatElement(packed[i], count: 1 - n))
                i += 1
            }
            guard out.count <= length else { throw FormatError("row \(row) unpacks to more than \(length) bytes") }
        }
        guard out.count == length else { throw FormatError("row \(row) unpacks to \(out.count) bytes, not \(length)") }
        return out
    }
}
