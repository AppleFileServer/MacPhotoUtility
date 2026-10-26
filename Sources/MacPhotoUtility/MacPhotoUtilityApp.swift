import AppKit
import SwiftUI
import UniformTypeIdentifiers
import MacPhotoKit

/// MacPhoto Utility: one window, one project, a queue of photographs
/// (Phases 3–5).
@main
struct MacPhotoUtilityApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var queue = PhotoQueue()
    @State private var recent = Recent.projects
    private var session: EditorSession { queue.editor }

    var body: some Scene {
        Window("MacPhoto Utility", id: "main") {
            MainWindow(queue: queue)
                .onAppear { delegate.queue = queue }
                .background(WindowFinder { delegate.watch($0) })
                .onReceive(NotificationCenter.default.publisher(for: Recent.changed)) { _ in recent = Recent.projects }
        }
        .defaultSize(width: 1380, height: 860)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Project") { Panels.newProject(queue) }
                    .keyboardShortcut("n")
                Button("Open Project…") { Panels.openProject(queue) }
                    .keyboardShortcut("o")
                Menu("Open Recent") {
                    ForEach(recent, id: \.self) { url in
                        Button(url.deletingPathExtension().lastPathComponent) { Panels.openProject(queue, url) }
                    }
                    if !recent.isEmpty {
                        Divider()
                        Button("Clear Menu") { Recent.clear() }
                    }
                }
                .disabled(recent.isEmpty)
                Divider()
                Button("Add Photographs…") { Panels.addPhotographs(queue) }
                    .keyboardShortcut("i")
                Button("Add Folder…") { Panels.addFolder(queue) }
                    .keyboardShortcut("i", modifiers: [.command, .shift])
            }
            CommandGroup(replacing: .saveItem) {
                Button("Save") { _ = Panels.save(queue) }
                    .keyboardShortcut("s")
                Button("Save As…") { _ = Panels.save(queue, asNew: true) }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
            }
            CommandGroup(after: .saveItem) {
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

/// Opening files sent to the app, and asking before unsaved work is lost
/// (PH72): on quitting and on closing the window.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var queue: PhotoQueue? { didSet { openWaiting() } }
    private var waiting: [URL] = []
    private var guardWindow: CloseGuard?
    /// The question has been answered for this quit; don't ask twice.
    private var leaving = false

    private func openWaiting() {
        guard !waiting.isEmpty, let queue else { return }
        let urls = waiting
        waiting = []
        let projects = urls.filter { $0.pathExtension.lowercased() == ProjectFile.fileExtension }
        if let p = projects.first { Panels.openProject(queue, p) }
        let photos = urls.filter { $0.pathExtension.lowercased() != ProjectFile.fileExtension }
        if !photos.isEmpty { Task { await queue.add(photos) } }
    }

    /// Files sent to the app while it's starting come through SwiftUI, which
    /// then makes the window (it doesn't make one if the event is taken
    /// from it at launch).
    func application(_ application: NSApplication, open urls: [URL]) {
        waiting += urls
        openWaiting()
    }

    /// Files sent once it's running (the Dock icon, Open With, a double-
    /// clicked project) are taken here, before SwiftUI sees them: SwiftUI's
    /// own handling closes this window to "activate" one for the file, and
    /// with no window left the app quits (found in Phase 5).
    private func takeOpenEvents() {
        NSAppleEventManager.shared().setEventHandler(
            self, andSelector: #selector(openDocuments(_:withReply:)),
            forEventClass: AEEventClass(kCoreEventClass), andEventID: AEEventID(kAEOpenDocuments))
    }

    @objc func openDocuments(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        guard let direct = event.paramDescriptor(forKeyword: keyDirectObject) else { return }
        // One file comes as itself, several as a list.
        let items = direct.descriptorType == typeAEList
            ? (0..<direct.numberOfItems).compactMap { direct.atIndex($0 + 1) } : [direct]
        // The Finder sends bookmarks ('bmrk'); fileURLValue resolves those too.
        let urls = items.compactMap { d -> URL? in
            if let u = d.fileURLValue { return u }
            var stale = false
            return try? URL(resolvingBookmarkData: d.data, options: [.withoutUI], bookmarkDataIsStale: &stale)
        }
        waiting += urls
        openWaiting()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        // After any launch-time file has gone through SwiftUI.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.takeOpenEvents() }
    }

    /// Quits when the project's window has closed, and only then: when a
    /// file is sent to the app, SwiftUI opens and closes a window of its own
    /// for a moment, which AppKit took for the last window closing.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !leaving, let queue else { return .terminateNow }
        return Panels.confirmDiscard(queue) ? .terminateNow : .terminateCancel
    }

    /// Asks before the window closes; closing the window quits.
    func watch(_ window: NSWindow) {
        guard guardWindow?.window !== window else { return }
        guardWindow = CloseGuard(window: window) { [weak self] in
            guard let self, let queue = self.queue, !self.leaving else { return true }
            guard Panels.confirmDiscard(queue) else { return false }
            self.leaving = true
            return true
        }
    }
}

/// Recently opened projects, for File ▸ Open Recent.
enum Recent {
    static let changed = Notification.Name("MacPhotoRecentProjectsChanged")
    private static let key = "recentProjects"

    static var projects: [URL] {
        (UserDefaults.standard.stringArray(forKey: key) ?? [])
            .map { URL(fileURLWithPath: $0) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    static func note(_ url: URL) {
        var list = (UserDefaults.standard.stringArray(forKey: key) ?? []).filter { $0 != url.path }
        list.insert(url.path, at: 0)
        UserDefaults.standard.set(Array(list.prefix(10)), forKey: key)
        NotificationCenter.default.post(name: changed, object: nil)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
        NotificationCenter.default.post(name: changed, object: nil)
    }
}

/// The panels and questions: projects, photographs, folders.
@MainActor
enum Panels {
    static let projectType = UTType(exportedAs: "local.macphoto.project", conformingTo: .json)

    // MARK: Projects (PH71, PH72)

    /// Save, Don't Save or Cancel, if there's anything unsaved. True to go on.
    static func confirmDiscard(_ queue: PhotoQueue) -> Bool {
        guard queue.isDirty else { return true }
        let alert = NSAlert()
        alert.messageText = "Do you want to save the changes to “\(queue.title)”?"
        alert.informativeText = "Your framing, settings and export history are only kept if you save the project. The photographs themselves aren't changed either way."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")
        alert.buttons[1].hasDestructiveAction = true
        switch alert.runModal() {
        case .alertFirstButtonReturn: return save(queue)
        case .alertSecondButtonReturn: return true
        default: return false
        }
    }

    /// Saves to the project's file, or asks where if it hasn't one. True if saved.
    @discardableResult
    static func save(_ queue: PhotoQueue, asNew: Bool = false) -> Bool {
        var url = queue.projectURL
        if url == nil || asNew {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [projectType]
            panel.nameFieldStringValue = queue.title
            panel.message = "A project keeps the queue, each photograph's framing, the settings and the export history; not the photographs."
            guard panel.runModal() == .OK, let chosen = panel.url else { return false }
            url = chosen
        }
        guard let url else { return false }
        do {
            try queue.save(to: url)
            Recent.note(url)
            return true
        } catch {
            queue.editor.message = .init(title: "The project wasn't saved.", detail: error.localizedDescription)
            return false
        }
    }

    static func newProject(_ queue: PhotoQueue) {
        guard confirmDiscard(queue) else { return }
        queue.newProject()
    }

    /// Opens a project, chosen in a panel if `url` is nil; reports moved and
    /// missing photographs (PH73).
    static func openProject(_ queue: PhotoQueue, _ url: URL? = nil) {
        guard confirmDiscard(queue) else { return }
        var target = url
        if target == nil {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [projectType]
            panel.message = "Choose a MacPhoto project."
            guard panel.runModal() == .OK else { return }
            target = panel.url
        }
        guard let target else { return }
        Task {
            do {
                let r = try await queue.openProject(target)
                Recent.note(target)
                var lines = [String]()
                if !r.moved.isEmpty {
                    lines.append("Found where they had moved to, by their content: \(r.moved.joined(separator: ", ")). Save the project to remember the new places.")
                }
                if !r.missing.isEmpty {
                    lines.append("Not found: \(r.missing.joined(separator: ", ")). Their framing is kept; select one and use Locate… to find it.")
                }
                if !lines.isEmpty {
                    queue.editor.message = .init(title: "“\(queue.title)” is open.", detail: lines.joined(separator: "\n\n"))
                }
            } catch {
                queue.editor.message = .init(title: "The project couldn't be opened.", detail: "\(error)")
            }
        }
    }

    // MARK: Relinking (PH74)

    static func locate(_ queue: PhotoQueue, _ id: UUID) {
        guard let e = queue.entries.first(where: { $0.id == id }) else { return }
        let panel = NSOpenPanel()
        panel.message = "Where is “\(e.name)” now?"
        panel.allowedContentTypes = [.jpeg, .heic, .heif, .png, .tiff]
        panel.directoryURL = e.url.deletingLastPathComponent()
        guard panel.runModal() == .OK, let url = panel.url else { return }
        Task {
            switch await queue.relink(id, to: url) {
            case .linked: break
            case .unreadable(let why):
                queue.editor.message = .init(title: "That file can't be used.", detail: why)
            case .differs:
                let alert = NSAlert()
                alert.messageText = "This isn't the same photograph."
                alert.informativeText = "“\(url.lastPathComponent)” has different content from the photograph the project remembers. Use it anyway, keeping the framing?"
                alert.addButton(withTitle: "Cancel")
                alert.addButton(withTitle: "Use It Anyway")
                guard alert.runModal() == .alertSecondButtonReturn else { return }
                if case .unreadable(let why) = await queue.relinkAcceptingDifferent(id, to: url) {
                    queue.editor.message = .init(title: "That file can't be used.", detail: why)
                }
            }
        }
    }

    static func locateInFolder(_ queue: PhotoQueue) {
        let panel = NSOpenPanel()
        panel.message = "Choose a folder to look in for the missing photographs."
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = "Look Here"
        guard panel.runModal() == .OK, let folder = panel.url else { return }
        Task {
            let found = await queue.locate(inFolder: folder)
            let still = queue.entries.filter { $0.state == .missing }.count
            queue.editor.message = .init(
                title: found == 0 ? "None of the missing photographs are there." : "Found \(found).",
                detail: still == 0 ? "Nothing is missing now." : "\(still) still missing.")
        }
    }

    // MARK: Photographs and folders

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


