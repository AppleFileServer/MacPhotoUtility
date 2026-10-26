import Foundation
import MacPhotoKit

// mpu: the developer's harness (SPECIFICATION.md §10, "Test tools"). Phase 0
// prints the fixed profiles; Phase 1 adds converting one photograph.

let args = Array(CommandLine.arguments.dropFirst())

func usage() -> Never {
    print("usage: mpu profiles | mpu version")
    exit(2)
}

switch args.first {
case "profiles":
    print("Print: 2.5 x 3.5 in, 8-bit greyscale")
    for r in PrintResolution.allCases {
        for o in Orientation.allCases {
            let p = PrintProfile(orientation: o, resolution: r).pixels
            print("  \(r.ppi) PPI \(o.rawValue): \(p.width) x \(p.height) px")
        }
    }
    print("Screen: \(ScreenImage.width) x \(ScreenImage.height) px, 1-bit, Atkinson")
    print("MacPaint page: \(MacPaintPage.width) x \(MacPaintPage.height) px")
case "version":
    print("MacPhoto Utility \(AppVersion.string)")
default:
    usage()
}
