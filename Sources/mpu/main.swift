import Foundation
import MacPhotoKit
import MacPhotoTestSupport

// mpu: the developer's harness (SPECIFICATION.md §10, "Test tools"). It runs
// the engine without the window: Phase 1 converts one photograph.

let args = Array(CommandLine.arguments.dropFirst())

func usage() -> Never {
    print("""
    usage: mpu profiles
           mpu convert PHOTO [--ppi 300|360] [--orientation portrait|landscape]
                       [--turns N] [--print-crop X,Y,ZOOM] [--screen-crop X,Y,ZOOM]
                       [--preview DIR]
           mpu compare PHOTO --out DIR [--set all|pair] [--turns N] [--screen-crop X,Y,ZOOM]
           mpu testimages DIR
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
        var resolution = PrintResolution.standard
        if let p = o["--ppi"] {
            guard let n = Int(p), let r = PrintResolution(rawValue: n) else { fail("--ppi is 300 or 360") }
            resolution = r
        }
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
