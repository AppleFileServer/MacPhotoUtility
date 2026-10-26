import AppKit
import SwiftUI
import MacPhotoKit

/// Output and export (PH51): the PPI, the files, the folder, Export, and
/// what the last export wrote.
struct OutputPanel: View {
    @Bindable var session: EditorSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Output").font(.headline)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Print resolution").font(.subheadline.weight(.medium))
                    Picker("Print resolution", selection: $session.settings.resolution) {
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

                HStack {
                    Button {
                        Task { await session.export() }
                    } label: {
                        Text("Export").frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .disabled(!session.canExport)
                    if session.isExporting { ProgressView().controlSize(.small) }
                }

                if let result = session.lastExport { exported(result.files) }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

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
