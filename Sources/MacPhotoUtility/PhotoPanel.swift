import SwiftUI
import MacPhotoKit

/// The photograph's details (PH47). Phase 4's queue goes here.
struct PhotoPanel: View {
    let session: EditorSession

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Photograph").font(.headline)
            if let p = session.photo {
                VStack(alignment: .leading, spacing: 6) {
                    Text(p.url.lastPathComponent)
                        .font(.body.weight(.medium))
                        .lineLimit(2)
                        .textSelection(.enabled)
                    detail("Kind", p.kind)
                    detail("Stored", "\(p.storedWidth) × \(p.storedHeight)")
                    detail("Upright", "\(p.image.width) × \(p.image.height)")
                    detail("Orientation", Self.orientation(p.exifOrientation))
                    if let c = session.composition, c.quarterTurns != 0 {
                        detail("Turned", "\(c.quarterTurns * 90)° clockwise")
                    }
                }
                Text(status)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Status: \(status)")
                Button("Close Photograph") { session.close() }
            } else if session.isOpening {
                ProgressView("Opening…")
            } else {
                Text("Open a photograph with File ▸ Open Photograph… (⌘O), or drag one onto this window.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Open Photograph…") { Panels.openPhotograph(session) }
            }
            Spacer()
            Text("MacPhoto Utility \(AppVersion.string)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var status: String {
        if session.isOpening { return "Opening…" }
        if session.isExporting { return "Exporting…" }
        if session.isRendering { return "Updating the previews…" }
        return "Ready"
    }

    private func detail(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).foregroundStyle(.secondary).frame(width: 86, alignment: .leading)
            Text(value)
        }
        .font(.callout)
        .accessibilityElement(children: .combine)
    }

    static func orientation(_ n: Int) -> String {
        switch n {
        case 1: "upright as stored"
        case 2: "mirrored (EXIF 2)"
        case 3: "turned 180° (EXIF 3)"
        case 4: "upside down, mirrored (EXIF 4)"
        case 5: "turned and mirrored (EXIF 5)"
        case 6: "turned 90° right (EXIF 6)"
        case 7: "turned and mirrored (EXIF 7)"
        case 8: "turned 90° left (EXIF 8)"
        default: "EXIF \(n)"
        }
    }
}
