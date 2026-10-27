import Foundation
import MacPhotoKit
import MacPhotoTestSupport

// mpu: the developer's harness (SPECIFICATION.md §10, "Test tools"). It runs
// the engine without the window: Phase 1 converts one photograph.

let args = Array(CommandLine.arguments.dropFirst())
setvbuf(stdout, nil, _IOLBF, 0)        // messages and errors in the order they happen

func usage() -> Never {
    print("""
    usage: mpu profiles
           mpu convert PHOTO [--ppi 300|360] [--orientation portrait|landscape]
                       [--turns N] [--print-crop X,Y,ZOOM] [--screen-crop X,Y,ZOOM]
                       [--preview DIR]
           mpu export PHOTO --to DIR [same options as convert, but --preview]
                      [--only print,screen,macpaint] [--if-exists stop|replace|keep-both]
           mpu validate FILE...
           mpu compare PHOTO --out DIR [--set all|pair] [--turns N] [--screen-crop X,Y,ZOOM]
           mpu dither PHOTO --out PNG [--width N] [--centre X,Y]
           mpu testimages DIR
           mpu fixtures DIR
           mpu version
    """)
    exit(2)
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("mpu: \(message)\n".utf8))
    exit(1)
}

/// The options after the photograph, as "--name value" pairs.
func options(_ list: ArraySlice<String>, allowed: Set<String>) -> [String: String] {
    var out = [String: String]()
    var i = list.startIndex
    while i < list.endIndex {
        let name = list[i]
        guard allowed.contains(name), i + 1 < list.endIndex else { usage() }
        out[name] = list[i + 1]
        i += 2
    }
    return out
}

func crop(_ text: String?) -> Crop? {
    guard let text else { return nil }
    let parts = text.split(separator: ",").compactMap { Double($0) }
    guard parts.count == 3 else { fail("a crop is X,Y,ZOOM, e.g. 0.5,0.4,1.5") }
    return Crop(centreX: parts[0], centreY: parts[1], zoom: parts[2])
}

/// Loads the photograph and builds its composition from the options.
func resolution(_ o: [String: String]) -> PrintResolution {
    guard let p = o["--ppi"] else { return .standard }
    guard let n = Int(p), let r = PrintResolution(rawValue: n) else { fail("--ppi is 300 or 360") }
    return r
}

/// Recognises a file by its content, as the Transfer Utility will, and checks it.
func validate(_ bytes: [UInt8]) -> (kind: String, result: Result<String, FormatError>) {
    func attempt(_ body: () throws -> String) -> Result<String, FormatError> {
        do { return .success(try body()) } catch let e as FormatError { return .failure(e) }
        catch { return .failure(FormatError("\(error)")) }
    }
    let version = bytes.count > 524 ? Array(bytes[522..<524]) : []
    if version == [0x11, 0x01] {
        return ("screen PICT", attempt { _ = try ScreenPICTValidator.validate(bytes); return "512 x 342, 1-bit" })
    }
    if version == [0x00, 0x11] {
        return ("print PICT", attempt {
            let r = try PrintPICTValidator.validate(bytes).record
            let p = r.profile.pixels
            return "\(p.width) x \(p.height), 8-bit, \(r.profile.resolution.ppi) PPI, \(r.profile.orientation.rawValue)"
                + String(format: ", CRC-32 %08X", r.pixelChecksum)
        })
    }
    return ("MacPaint", attempt { _ = try MacPaintValidator.validate(bytes); return "576 x 720 page, screen image centred" })
}

func prepare(_ path: String, _ o: [String: String]) -> (ImportedPhoto, Composition) {
    let photo: ImportedPhoto
    do { photo = try Importer.load(URL(fileURLWithPath: path)) } catch { fail("\(error)") }
    let img = photo.image
    var c = Composition(uprightWidth: img.width, height: img.height)
    if let t = o["--turns"] { guard let n = Int(t) else { usage() }; c.turn(by: n) }
    if let s = o["--orientation"] {
        guard let or = Orientation(rawValue: s) else { usage() }
        c.setOrientation(or)
    }
    if let p = crop(o["--print-crop"]) { c.printCrop = p }
    if let s = crop(o["--screen-crop"]) { c.screenCrop = s }
    return (photo, c)
}

func describe(_ photo: ImportedPhoto) {
    print("Photograph: \(photo.url.lastPathComponent), \(photo.kind), \(photo.storedWidth) x \(photo.storedHeight) stored,"
          + " EXIF orientation \(photo.exifOrientation), upright \(photo.image.width) x \(photo.image.height)")
}

do {
    switch args.first {
    case "profiles":
        print("Print: 2.5 x 3.5 in, 8-bit greyscale")
        for r in PrintResolution.allCases {
            for o in Orientation.allCases {
                let p = PrintProfile(orientation: o, resolution: r).pixels
                let mark = r == .standard ? " (default)" : ""
                print("  \(r.ppi) PPI \(o.rawValue): \(p.width) x \(p.height) px\(mark)")
            }
        }
        print("Screen: \(ScreenImage.width) x \(ScreenImage.height) px, 1-bit, Atkinson")
        print("MacPaint page: \(MacPaintPage.width) x \(MacPaintPage.height) px")

    case "convert":
        guard args.count >= 2 else { usage() }
        let o = options(args.dropFirst(2), allowed: ["--ppi", "--orientation", "--turns",
                                                     "--print-crop", "--screen-crop", "--preview"])
        let resolution = resolution(o)
        let (photo, c) = prepare(args[1], o)
        describe(photo)
        print("Composition: \(c.quarterTurns) quarter turn(s), \(c.orientation.rawValue)")
        let print_ = PrintRenderer.render(photo.image, c, resolution: resolution)
        let screen = ScreenRenderer.render(photo.image, c)
        print("Print: crop \(print_.source) -> \(print_.image.width) x \(print_.image.height) at \(resolution.ppi) PPI, 8-bit")
        print("Screen: crop \(screen.source) -> 512 x 342, 1-bit \(DitherOptions.standard.label),"
              + " \(screen.bits.blackCount * 100 / (512 * 342))% black")
        for w in print_.warnings + screen.warnings { print("Warning: \(w)") }
        if let dir = o["--preview"] {
            let folder = URL(fileURLWithPath: dir)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try Preview.writePNG(Preview.cgImage(print_.image), to: folder.appendingPathComponent("print.png"),
                                 ppi: resolution.ppi)
            try Preview.writePNG(Preview.cgImage(screen.bits), to: folder.appendingPathComponent("screen.png"))
            print("Previews (not the real outputs): \(folder.path)/print.png, screen.png")
        }

    case "export":
        guard args.count >= 2 else { usage() }
        let o = options(args.dropFirst(2), allowed: ["--to", "--ppi", "--orientation", "--turns", "--print-crop",
                                                     "--screen-crop", "--only", "--if-exists"])
        guard let to = o["--to"] else { usage() }
        var kinds = Set(OutputKind.allCases)
        if let only = o["--only"] {
            let names = ["print": OutputKind.print, "screen": .screen, "macpaint": .macPaint]
            kinds = Set(try only.split(separator: ",").map { s -> OutputKind in
                guard let k = names[String(s)] else { throw FormatError("--only takes print, screen, macpaint") }
                return k
            })
        }
        guard let ifExists = IfExists(rawValue: o["--if-exists"] ?? "stop") else { usage() }
        let (photo, c) = prepare(args[1], o)
        describe(photo)
        let folder = URL(fileURLWithPath: to)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let result = try Exporter.export(photo, c, resolution: resolution(o), kinds: kinds, to: folder, ifExists: ifExists)
        for f in result.files { print("Exported and checked: \(f.path) (\(f.bytes) bytes)") }
        for w in result.warnings { print("Warning: \(w)") }
        print("Manifest: \(folder.path)/manifest.json")

    case "validate":
        guard args.count >= 2 else { usage() }
        var failures = 0
        for path in args.dropFirst() {
            let name = (path as NSString).lastPathComponent
            guard let data = FileManager.default.contents(atPath: path) else { print("\(name): can't be read"); failures += 1; continue }
            let (kind, result) = validate([UInt8](data))
            switch result {
            case .success(let what): print("\(name): valid \(kind), \(what)")
            case .failure(let e): print("\(name): not a valid \(kind): \(e)"); failures += 1
            }
        }
        if failures > 0 { exit(1) }

    case "compare":
        // PH32: the screen image dithered seven ways, for Jack to choose from.
        guard args.count >= 2 else { usage() }
        let o = options(args.dropFirst(2), allowed: ["--out", "--set", "--turns", "--screen-crop"])
        // "pair": just Atkinson and Floyd–Steinberg, three across.
        guard ["all", "pair"].contains(o["--set"] ?? "all") else { usage() }
        let pair = o["--set"] == "pair"
        guard let out = o["--out"] else { usage() }
        let (photo, c) = prepare(args[1], o)
        describe(photo)
        let variants = pair ? [DitherOptions(), DitherOptions(method: .floydSteinberg, serpentine: true)] : [
            DitherOptions(),
            DitherOptions(serpentine: true),
            DitherOptions(linearTone: true),
            DitherOptions(sharpen: true),
            DitherOptions(serpentine: true, linearTone: true, sharpen: true),
            DitherOptions(method: .floydSteinberg, serpentine: true),
            DitherOptions(method: .floydSteinberg, serpentine: true, linearTone: true),
        ]
        let base = ScreenRenderer.render(photo.image, c)
        var panels = [(label: "Grey, before dithering (for reference)", image: Preview.cgImage(base.grey))]
        let folder = URL(fileURLWithPath: out)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let stem = photo.url.deletingPathExtension().lastPathComponent
        try Preview.writePNG(Preview.cgImage(base.grey), to: folder.appendingPathComponent("\(stem)-1-grey.png"))
        for (i, v) in variants.enumerated() {
            let bits = Dither.dither(base.grey, options: v)
            let label = i == 0 ? "\(v.label) (the specification's)" : v.label
            panels.append((label, Preview.cgImage(bits)))
            let file = String(format: "%@-%d-%@.png", stem, i + 2, v.label.lowercased()
                .replacingOccurrences(of: "–", with: "-").replacingOccurrences(of: ", ", with: "-")
                .replacingOccurrences(of: " ", with: "-"))
            try Preview.writePNG(Preview.cgImage(bits), to: folder.appendingPathComponent(file))
        }
        let sheet = folder.appendingPathComponent("compare-\(stem).png")
        try Preview.writePNG(Preview.sheet(panels, columns: pair ? 3 : 2), to: sheet)
        for w in base.warnings { print("Warning: \(w)") }
        print("Sheet: \(sheet.path)")

    case "fixtures":
        // The handoff fixtures (PH42), for Fixtures/handoff/.
        guard args.count == 2 else { usage() }
        let items = try HandoffFixtures.make(into: URL(fileURLWithPath: args[1]))
        for i in items { print("\(i.name): \(i.valid ? "good" : "bad"), \(i.tests)") }

    case "dither":
        // The manual's chapter openers (MANUAL-PLAN.md, MG4): a photograph
        // as MacPhoto's own screen image, 342 dots high like the Plus's
        // screen but as wide as asked, centred (or at X,Y), plain Atkinson.
        guard args.count >= 2 else { usage() }
        let o = options(args.dropFirst(2), allowed: ["--out", "--width", "--centre"])
        guard let out = o["--out"] else { usage() }
        let w = Int(o["--width"] ?? "512") ?? 512, h = ScreenImage.height
        let photo: ImportedPhoto
        do { photo = try Importer.load(URL(fileURLWithPath: args[1])) } catch { fail("\(error)") }
        let img = photo.image, aspect = Double(w) / Double(h)
        var cx = 0.5, cy = 0.5
        if let c = o["--centre"] {
            let v = c.split(separator: ",").compactMap { Double($0) }
            guard v.count == 2 else { fail("--centre is X,Y, fractions of the photograph") }
            cx = v[0]; cy = v[1]
        }
        let wide = Double(img.width) / Double(img.height) > aspect
        let cw = wide ? Int((Double(img.height) * aspect).rounded()) : img.width
        let ch = wide ? img.height : Int((Double(img.width) / aspect).rounded())
        let x = min(max(Int(cx * Double(img.width)) - cw / 2, 0), img.width - cw)
        let y = min(max(Int(cy * Double(img.height)) - ch / 2, 0), img.height - ch)
        let grey = Resampler.region(img, turns: 0, rect: PixelRect(x: x, y: y, width: cw, height: ch), to: w, h)
        try Preview.writePNG(Preview.cgImage(Dither.dither(grey)), to: URL(fileURLWithPath: out))
        print("\(photo.url.lastPathComponent): \(cw) x \(ch) at (\(x), \(y)) -> \(w) x \(h), Atkinson: \(out)")

    case "testimages":
        // The synthetic test images (PH31), for looking at.
        guard args.count == 2 else { usage() }
        let folder = URL(fileURLWithPath: args[1])
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for (spec, url) in zip(TestImages.all, try TestImages.writeAll(to: folder)) {
            print("\(url.lastPathComponent): \(spec.purpose)")
        }

    case "version":
        print("MacPhoto Utility \(AppVersion.string)")

    default:
        usage()
    }
} catch {
    fail("\(error)")
}
