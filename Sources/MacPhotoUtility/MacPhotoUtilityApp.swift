import AppKit
import SwiftUI
import MacPhotoKit

/// MacPhoto Utility: one window, a queue of photographs (Phases 3–4).
@main
struct MacPhotoUtilityApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var queue = PhotoQueue()
    private var session: EditorSession { queue.editor }

    var body: some Scene {
        Window("MacPhoto Utility", id: "main") {
            MainWindow(queue: queue)
                .onAppear { delegate.queue = queue }
        }
        .defaultSize(width: 1380, height: 860)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Photographs…") { Panels.addPhotographs(queue) }
                    .keyboardShortcut("o")
                Button("Add Folder…") { Panels.addFolder(queue) }
                    .keyboardShortcut("o", modifiers: [.command, .shift])
            }
            CommandGroup(after: .newItem) {
                Divider()
                Button("Export This Photograph") { Task { await session.export() } }
                    .keyboardShortcut("e")
                    .disabled(!session.canExport || queue.isExporting)
                Button("Export All") { Task { await queue.exportAll() } }
                    .keyboardShortcut("e", modifiers: [.command, .shift])
                    .disabled(queue.entries.isEmpty || queue.isExporting)
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
    weak var queue: PhotoQueue? { didSet { addWaiting() } }
    private var waiting: [URL] = []

    private func addWaiting() {
        guard !waiting.isEmpty, let queue else { return }
        let urls = waiting
        waiting = []
        Task { await queue.add(urls) }
    }

    /// Photographs or folders dropped on the Dock icon or opened with the app.
    func application(_ application: NSApplication, open urls: [URL]) {
        waiting += urls
        addWaiting()
    }

    /// Nothing is saved yet (PH68): ask before losing changed framing.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let n = queue?.unexportedChanges ?? 0
        guard n > 0 else { return .terminateNow }
        let alert = NSAlert()
        alert.messageText = n == 1 ? "Quit and lose the framing of 1 photograph?"
                                   : "Quit and lose the framing of \(n) photographs?"
        alert.informativeText = "Their crops, turns and screen settings have changed since they were last exported, and the queue isn't saved yet."
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Quit")
        alert.buttons[1].hasDestructiveAction = true
        return alert.runModal() == .alertSecondButtonReturn ? .terminateNow : .terminateCancel
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
    static func addPhotographs(_ queue: PhotoQueue) {
        let panel = NSOpenPanel()
        panel.message = "Choose photographs: JPEG, HEIC, PNG or TIFF."
        panel.allowedContentTypes = [.jpeg, .heic, .heif, .png, .tiff]
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        let urls = panel.urls
        Task { await queue.add(urls) }
    }

    static func addFolder(_ queue: PhotoQueue) {
        let panel = NSOpenPanel()
        panel.message = "Choose a folder: the photographs directly inside it are added."
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Add"
        guard panel.runModal() == .OK else { return }
        let urls = panel.urls
        Task { await queue.add(urls) }
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
