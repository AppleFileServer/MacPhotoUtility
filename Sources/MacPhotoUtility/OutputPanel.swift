import AppKit
import SwiftUI
import MacPhotoKit

/// Output and export (PH51, PH64): the shared settings (PPI, files,
/// folder), Export This and Export All with progress, and what the last
/// single export wrote.
struct OutputPanel: View {
    let queue: PhotoQueue
    private var session: EditorSession { queue.editor }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Output").font(.headline)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Print resolution").font(.subheadline.weight(.medium))
                    Picker("Print resolution", selection: Binding(
                        get: { session.settings.resolution }, set: { session.settings.resolution = $0 })) {
                        Text("360 PPI").tag(PrintResolution.ppi360)
                        Text("300 PPI").tag(PrintResolution.ppi300)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    Text("The framing stays the same either way.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Files").font(.subheadline.weight(.medium))
                    toggle(.print, "Print PICT", "8-bit grey, for MacPhoto")
                    toggle(.screen, "Screen PICT", "1-bit, 512 × 342")
                    toggle(.macPaint, "MacPaint", "the screen image, centred")
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Folder").font(.subheadline.weight(.medium))
                    Text(session.settings.destination?.path ?? "None chosen")
                        .font(.callout)
                        .foregroundStyle(session.settings.destination == nil ? .secondary : .primary)
                        .lineLimit(3)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                    Button("Choose…") { Panels.chooseDestination(session) }
                    Text("Files go into Print Files, PICT Files and MacPaint Files inside it.")
                        .font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 8) {
                    Button {
                        Task { await queue.exportAll() }
                    } label: {
                        Text(exportAllTitle).frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .disabled(readyCount == 0 || queue.isExporting || session.settings.destination == nil
                              || session.settings.outputs.isEmpty)
                    Button {
                        Task { await session.export() }
                    } label: {
                        Text("Export This Photograph").frame(maxWidth: .infinity)
                    }
                    .disabled(!session.canExport || queue.isExporting)
                    if session.isExporting { ProgressView().controlSize(.small) }
                }

                if let p = queue.progress {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: Double(p.index - 1), total: Double(p.total))
                        Text("\(p.index) of \(p.total): \(p.name)").font(.caption).lineLimit(1).truncationMode(.middle)
                        Button("Stop") { queue.stop() }
                            .help("Stop after the photograph being exported now")
                    }
                }

                if let result = session.lastExport, !queue.isExporting { exported(result.files) }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var readyCount: Int { queue.entries.filter { $0.state == .ready }.count }

    private var exportAllTitle: String { readyCount == 0 ? "Export All" : "Export All (\(readyCount))" }

    private func toggle(_ kind: OutputKind, _ title: String, _ note: String) -> some View {
        Toggle(isOn: Binding(
            get: { session.settings.outputs.contains(kind) },
            set: { on in
                if on { session.settings.outputs.insert(kind) } else { session.settings.outputs.remove(kind) }
            })) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                Text(note).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func exported(_ files: [ExportedFile]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Exported and checked", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.subheadline.weight(.medium))
            ForEach(files, id: \.path) { f in
                Text("\(f.path)  (\(ByteCountFormatter.string(fromByteCount: Int64(f.bytes), countStyle: .file)))")
                    .font(.caption)
                    .textSelection(.enabled)
            }
            Text("Not yet on the Plus: use the Macintosh Transfer Utility.")
                .font(.caption).foregroundStyle(.secondary)
            Button("Show in Finder") {
                guard let folder = session.settings.destination else { return }
                NSWorkspace.shared.activateFileViewerSelecting(
                    files.map { folder.appendingPathComponent($0.path) })
            }
        }
    }
}
