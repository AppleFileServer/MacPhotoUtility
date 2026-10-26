import SwiftUI
import MacPhotoKit

/// The window (PH47, PH62): the queue on the left, the composition editor
/// and the two previews in the middle, output and export on the right.
struct MainWindow: View {
    let queue: PhotoQueue
    @State private var dropTargeted = false
    @State private var window: NSWindow?

    private var session: EditorSession { queue.editor }

    var body: some View {
        HStack(spacing: 0) {
            QueuePanel(queue: queue)
                .frame(width: 240)
            Divider()
            VStack(spacing: 0) {
                CompositionEditor(session: session)
                    .frame(minHeight: 300)
                Divider()
                PreviewsRow(session: session)
            }
            .frame(minWidth: 830)
            Divider()
            OutputPanel(queue: queue)
                .frame(width: 290)
        }
        .frame(minHeight: 760)
        // The project's name and the edited mark in the title bar (PH71).
        .navigationTitle(queue.title)
        .background(WindowFinder { window = $0; updateWindow() })
        .onChange(of: queue.isDirty) { updateWindow() }
        .onChange(of: queue.projectURL) { updateWindow() }
        .overlay {
            if dropTargeted {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.accentColor, lineWidth: 4)
                    .padding(4)
                    .allowsHitTesting(false)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard !urls.isEmpty else { return false }
            Task { await queue.add(urls) }
            return true
        } isTargeted: { dropTargeted = $0 }
        .alert(session.message?.title ?? "", isPresented: Binding(
            get: { session.message != nil }, set: { if !$0 { session.message = nil } }
        ), presenting: session.message) { _ in
            Button("OK") { session.message = nil }
        } message: { m in
            Text(m.detail)
        }
        // Export This: names already taken (PH51).
        .confirmationDialog("Some of these files are already there.", isPresented: Binding(
            get: { session.conflict != nil }, set: { _ in }       // answered by the buttons only
        )) {
            // Keep Both first, as the default: Return never overwrites anything.
            Button("Keep Both") { Task { await session.resolveConflict(.keepBoth) } }
                .keyboardShortcut(.defaultAction)
            Button("Replace", role: .destructive) { Task { await session.resolveConflict(.replace) } }
            Button("Cancel", role: .cancel) { Task { await session.resolveConflict(nil) } }
        } message: {
            Text((session.conflict ?? []).joined(separator: "\n")
                 + "\n\nReplace them, or keep both (the new files get a number)?")
        }
        // Export All: photographs not looked at (PH66).
        .confirmationDialog(unseenTitle, isPresented: Binding(
            get: { if case .unseen = queue.question { true } else { false } },
            set: { _ in }                                           // answered by the buttons only
        )) {
            Button("Export All") { Task { await queue.answer(.exportUnseen) } }
                .keyboardShortcut(.defaultAction)
            Button("Cancel", role: .cancel) { Task { await queue.answer(.cancel) } }
        } message: {
            Text(listed(unseenNames) + "\n\nThey'll be exported with the framing they started with: centred, full size.")
        }
        // Export All: names already taken in the folder (PH65).
        .confirmationDialog("Files for some photographs are already in the folder.", isPresented: Binding(
            get: { if case .taken = queue.question { true } else { false } },
            set: { _ in }                                           // answered by the buttons only
        )) {
            Button("Keep Both") { Task { await queue.answer(.keepBoth) } }
                .keyboardShortcut(.defaultAction)
            Button("Replace", role: .destructive) { Task { await queue.answer(.replace) } }
            Button("Skip Those Photographs") { Task { await queue.answer(.skipTaken) } }
            Button("Cancel", role: .cancel) { Task { await queue.answer(.cancel) } }
        } message: {
            Text(listed(takenNames) + "\n\nKeep both (the new files get a number), replace them, or leave those photographs out?")
        }
        .sheet(isPresented: Binding(get: { queue.summary != nil }, set: { if !$0 { queue.dismissSummary() } })) {
            if let s = queue.summary { SummarySheet(queue: queue, summary: s) }
        }
    }

    private func updateWindow() {
        window?.isDocumentEdited = queue.isDirty
        window?.representedURL = queue.projectURL
    }

    private var unseenNames: [String] { if case .unseen(let n) = queue.question { n } else { [] } }
    private var takenNames: [String] { if case .taken(let n) = queue.question { n } else { [] } }

    private var unseenTitle: String {
        let n = unseenNames.count
        return n == 1 ? "1 photograph hasn't been looked at." : "\(n) photographs haven't been looked at."
    }

    /// The first few names, then how many more.
    private func listed(_ names: [String]) -> String {
        let shown = names.prefix(8).joined(separator: "\n")
        return names.count > 8 ? shown + "\n…and \(names.count - 8) more" : shown
    }
}

/// What Export All did (PH64).
struct SummarySheet: View {
    let queue: PhotoQueue
    let summary: PhotoQueue.Summary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(summary.stopped ? "Export stopped" : "Export finished").font(.title3.weight(.semibold))
            Label("\(summary.exported.count) photograph\(summary.exported.count == 1 ? "" : "s") exported and checked (\(summary.files) files)",
                  systemImage: "checkmark.circle.fill").foregroundStyle(.green)
            if summary.warnings > 0 {
                Label("\(summary.warnings) warning\(summary.warnings == 1 ? "" : "s"): enlarged from a small photograph",
                      systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            }
            if !summary.renumbered.isEmpty {
                Text("Numbered because another photograph has the same name: \(summary.renumbered.joined(separator: ", "))")
                    .font(.callout).fixedSize(horizontal: false, vertical: true)
            }
            if !summary.skipped.isEmpty {
                Text("Left out, their files already there: \(summary.skipped.joined(separator: ", "))")
                    .font(.callout).fixedSize(horizontal: false, vertical: true)
            }
            if !summary.failed.isEmpty {
                Label("\(summary.failed.count) couldn't be exported:", systemImage: "xmark.octagon.fill")
                    .foregroundStyle(.red)
                ScrollView {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(Array(summary.failed.enumerated()), id: \.offset) { _, f in
                            Text("\(f.name): \(f.reason)").font(.callout)
                        }
                    }
                }
                .frame(maxHeight: 140)
            }
            if summary.stopped {
                Text("Stopped before the rest; the files already written are complete and checked.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            Text("Not yet on the Plus: use the Macintosh Transfer Utility.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Button("Show in Finder") {
                    if let folder = queue.settings.destination { NSWorkspace.shared.activateFileViewerSelecting([folder]) }
                }
                Spacer()
                Button("Done") { queue.dismissSummary() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 460)
    }
}
