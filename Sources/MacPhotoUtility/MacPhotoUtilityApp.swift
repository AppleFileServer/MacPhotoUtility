import AppKit
import SwiftUI
import MacPhotoKit

/// MacPhoto Utility: one window for one photograph (Phase 3; PH46–PH55).
@main
struct MacPhotoUtilityApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var session = EditorSession()

    var body: some Scene {
        Window("MacPhoto Utility", id: "main") {
            MainWindow(session: session)
                .onAppear { delegate.session = session }
        }
        .defaultSize(width: 1380, height: 860)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Photograph…") { Panels.openPhotograph(session) }
                    .keyboardShortcut("o")
                Button("Close Photograph") { session.close() }
                    .keyboardShortcut("w")
                    .disabled(session.photo == nil)
            }
            CommandGroup(after: .newItem) {
                Divider()
                Button("Export") { Task { await session.export() } }
                    .keyboardShortcut("e")
                    .disabled(!session.canExport)
            }
            CommandMenu("Photograph") {
                Button("Turn Left") { session.turn(by: -1) }
                    .keyboardShortcut("[")
                Button("Turn Right") { session.turn(by: 1) }
                    .keyboardShortcut("]")
                Divider()
                Button("Edit Print Crop") { session.editing = .print }
                    .keyboardShortcut("1")
                Button("Edit Screen Crop") { session.editing = .screen }
                    .keyboardShortcut("2")
                Button("Reset Crop") { session.resetCrop() }
                    .keyboardShortcut("0")
            }
        }
    }
}

/// Closing the window quits, as in the Transfer Utility; a bare executable
/// (swift run) still gets a Dock icon and menus.
final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var session: EditorSession? { didSet { openWaiting() } }
    private var waiting: URL?

    private func openWaiting() {
        guard let url = waiting, let session else { return }
        waiting = nil
        Task { await session.open(url) }
    }

    /// A photograph dropped on the Dock icon or opened with the app.
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        waiting = url
        openWaiting()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

/// The open and folder panels.
@MainActor
enum Panels {
    static func openPhotograph(_ session: EditorSession) {
        let panel = NSOpenPanel()
        panel.message = "Choose a photograph: JPEG, HEIC, PNG or TIFF."
        panel.allowedContentTypes = [.jpeg, .heic, .heif, .png, .tiff]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        Task { await session.open(url) }
    }

    static func chooseDestination(_ session: EditorSession) {
        let panel = NSOpenPanel()
        panel.message = "Choose the folder the files are exported into."
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        panel.directoryURL = session.settings.destination
        guard panel.runModal() == .OK, let url = panel.url else { return }
        session.settings.destination = url
    }
}
