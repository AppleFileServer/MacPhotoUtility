import SwiftUI
import MacPhotoKit

/// The window (PH47): the photograph on the left, the composition editor
/// and the two previews in the middle, output and export on the right.
struct MainWindow: View {
    @Bindable var session: EditorSession
    @State private var dropTargeted = false

    var body: some View {
        HStack(spacing: 0) {
            PhotoPanel(session: session)
                .frame(width: 230)
            Divider()
            VStack(spacing: 0) {
                CompositionEditor(session: session)
                    .frame(minHeight: 300)
                Divider()
                PreviewsRow(session: session)
            }
            .frame(minWidth: 880)
            Divider()
            OutputPanel(session: session)
                .frame(width: 290)
        }
        .frame(minHeight: 760)
        .overlay {
            if dropTargeted {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.accentColor, lineWidth: 4)
                    .padding(4)
                    .allowsHitTesting(false)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            Task { await session.open(url) }
            return true
        } isTargeted: { dropTargeted = $0 }
        .alert(session.message?.title ?? "", isPresented: Binding(
            get: { session.message != nil }, set: { if !$0 { session.message = nil } }
        ), presenting: session.message) { _ in
            Button("OK") { session.message = nil }
        } message: { m in
            Text(m.detail)
        }
        .confirmationDialog("Some of these files are already there.", isPresented: Binding(
            get: { session.conflict != nil }, set: { if !$0 { Task { await session.resolveConflict(nil) } } }
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
    }
}
