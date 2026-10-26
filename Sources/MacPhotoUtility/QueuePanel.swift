import SwiftUI
import MacPhotoKit

/// The queue (PH62): the photographs being worked on, the selected one's
/// details below. Removing takes a photograph out of the queue, never off
/// the disk.
struct QueuePanel: View {
    let queue: PhotoQueue
    @State private var selection = Set<UUID>()
    @State private var showSkipped = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Photographs").font(.headline)
                Spacer()
                Button { Panels.addPhotographs(queue) } label: { Image(systemName: "plus") }
                    .help("Add photographs (⌘I)")
                    .accessibilityLabel("Add photographs")
                Button { Panels.addFolder(queue) } label: { Image(systemName: "folder.badge.plus") }
                    .help("Add the photographs in a folder (⇧⌘I)")
                    .accessibilityLabel("Add a folder")
            }
            .padding(.horizontal, 12).padding(.vertical, 10)

            if queue.entries.isEmpty {
                Text("Add photographs with the + buttons, File ▸ Add Photographs… (⌘I), or by dragging photographs or a folder onto this window.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                Spacer()
            } else {
                List(selection: $selection) {
                    ForEach(queue.entries) { e in
                        QueueRow(entry: e, small: queue.isSmall(e)).tag(e.id)
                    }
                }
                .listStyle(.sidebar)
                .onDeleteCommand { queue.remove(selection); selection = [] }
                .onChange(of: selection) { _, new in
                    if new.count == 1, let id = new.first { Task { await queue.select(id) } }
                }
                .onChange(of: queue.entries.map(\.id)) { _, ids in selection.formIntersection(ids) }
                footer
            }
            Divider()
            details
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(countLine).font(.caption).foregroundStyle(.secondary)
            if let r = queue.lastAdd, !r.skipped.isEmpty {
                Button("\(r.skipped.count) skipped: not photographs…") { showSkipped = true }
                    .buttonStyle(.link).font(.caption)
                    .popover(isPresented: $showSkipped) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(r.skipped, id: \.self) { Text($0).font(.caption) }
                        }
                        .padding(12).frame(maxWidth: 360)
                    }
            }
            HStack {
                Button("Remove") { queue.remove(selection); selection = [] }
                    .disabled(selection.isEmpty)
                    .help("Take the selected photographs out of the queue (⌫); the files stay where they are")
                Button("Remove All") { queue.removeAll(); selection = [] }
            }
            .controlSize(.small)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }

    private var countLine: String {
        let n = queue.entries.count
        let bad = queue.entries.filter { if case .failed = $0.state { true } else { false } }.count
        var s = n == 1 ? "1 photograph" : "\(n) photographs"
        if bad > 0 { s += ", \(bad) can't be read" }
        if queue.isAdding { s += " · adding…" }
        return s
    }

    @ViewBuilder
    private var details: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let p = queue.editor.photo {
                Text(p.url.lastPathComponent).font(.callout.weight(.medium)).lineLimit(2).textSelection(.enabled)
                detail("Kind", p.kind)
                detail("Stored", "\(p.storedWidth) × \(p.storedHeight)")
                detail("Upright", "\(p.image.width) × \(p.image.height)")
                detail("Orientation", Self.orientation(p.exifOrientation))
                if let c = queue.editor.composition, c.quarterTurns != 0 {
                    detail("Turned", "\(c.quarterTurns * 90)° clockwise")
                }
                if let e = queue.entries.first(where: { $0.id == queue.editingID }) { history(e) }
            } else if queue.editor.isOpening {
                ProgressView("Opening…").controlSize(.small)
            } else if let e = selectedEntry, case .failed(let why) = e.state {
                Label(e.name, systemImage: "xmark.octagon.fill").foregroundStyle(.red).font(.callout)
                Text("Can't be read: \(why)").font(.caption).fixedSize(horizontal: false, vertical: true)
            } else if let e = selectedEntry, e.state == .missing {
                // PH73, PH74: missing, its framing kept until it's found.
                Label(e.name, systemImage: "questionmark.folder.fill").foregroundStyle(.orange).font(.callout)
                Text("Not found. It was at \(e.url.deletingLastPathComponent().path). Its framing is kept.")
                    .font(.caption).fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
                HStack {
                    Button("Locate…") { Panels.locate(queue, e.id) }
                    Button("Locate in Folder…") { Panels.locateInFolder(queue) }
                }
                .controlSize(.small)
            } else {
                Text(selection.count > 1 ? "\(selection.count) selected" : "No photograph selected")
                    .font(.callout).foregroundStyle(.secondary)
            }
            Spacer().frame(height: 4)
            Text("MacPhoto Utility \(AppVersion.string)").font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
    }

    private var selectedEntry: PhotoQueue.Entry? {
        guard selection.count == 1, let id = selection.first else { return nil }
        return queue.entries.first { $0.id == id }
    }

    /// The photograph's export history (PH76): exported and checked, never
    /// "transferred" or "printed".
    @ViewBuilder
    private func history(_ e: PhotoQueue.Entry) -> some View {
        if let last = e.history.last {
            let when = (ISO8601DateFormatter().date(from: last.date)).map {
                $0.formatted(date: .abbreviated, time: .shortened)
            } ?? last.date
            let n = e.history.count
            Text("Exported and checked \(n == 1 ? "once" : "\(n) times"); last \(when) to \(URL(fileURLWithPath: last.folder).lastPathComponent)")
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .help(e.history.reversed().map { r in
                    "\(r.date): " + r.files.map(\.path).joined(separator: ", ")
                }.joined(separator: "\n"))
        }
        if e.acceptedDifferentFile {
            Text("Linked to a different file than first added, on purpose.")
                .font(.caption).foregroundStyle(.orange)
        }
    }

    private func detail(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).foregroundStyle(.secondary).frame(width: 80, alignment: .leading)
            Text(value)
        }
        .font(.caption)
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

/// One photograph in the queue: thumbnail, name, P or L, status.
struct QueueRow: View {
    let entry: PhotoQueue.Entry
    let small: Bool

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 3).fill(.quaternary)
                if let t = entry.thumbnail {
                    Image(decorative: Pictures.cgImage(t), scale: 1)
                        .resizable().interpolation(.medium).aspectRatio(contentMode: .fit)
                }
            }
            .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name).lineLimit(1).truncationMode(.middle)
                Text(statusText).font(.caption).foregroundStyle(statusColour).lineLimit(1)
            }
            Spacer(minLength: 4)
            if let c = entry.composition, entry.state == .ready {
                Text(c.orientation == .portrait ? "P" : "L")
                    .font(.caption.weight(.semibold).monospaced())
                    .foregroundStyle(.secondary)
                    .help(c.orientation == .portrait ? "Printed portrait" : "Printed landscape")
            }
            statusIcon.frame(width: 16)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.name), \(statusText)")
    }

    private var statusText: String {
        switch entry.state {
        case .reading: return "Reading…"
        case .failed(let why): return "Can't be read: \(why)"
        case .missing: return "Missing: not where it was"
        case .ready:
            if entry.exported && !entry.changedSinceExport { return "Exported" }
            if small { return "Small for its output" }
            return entry.seen ? "Looked at" : "Not looked at yet"
        }
    }

    private var statusColour: Color {
        switch entry.state {
        case .failed: .red
        case .missing: .orange
        case .reading: .secondary
        case .ready: small && !(entry.exported && !entry.changedSinceExport) ? .orange : .secondary
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch entry.state {
        case .reading: ProgressView().controlSize(.mini)
        case .failed: Image(systemName: "xmark.octagon.fill").foregroundStyle(.red)
        case .missing: Image(systemName: "questionmark.folder.fill").foregroundStyle(.orange)
        case .ready:
            if entry.exported && !entry.changedSinceExport {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            } else if small {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            } else if !entry.seen {
                Image(systemName: "circle").foregroundStyle(.tertiary)
            }
        }
    }
}
