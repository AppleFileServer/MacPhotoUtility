import Foundation
import Observation

/// The photographs being worked on, in order (Phase 4; PH59–PH68): each
/// with its own framing, status and thumbnail, sharing one set of output
/// settings. The editor edits the selected one; Export All exports them
/// one at a time. Tested without a window.
@MainActor @Observable
public final class PhotoQueue {
    public enum State: Equatable, Sendable {
        case reading
        case ready
        case failed(String)
    }

    public struct Entry: Identifiable, Sendable {
        public let id = UUID()
        public let url: URL
        public var state: State = .reading
        public var kind: String?
        public var uprightWidth = 0, uprightHeight = 0
        public var thumbnail: GreyImage?
        /// The photograph's own framing (PH63); the default until edited.
        public var composition: Composition?
        /// Looked at in the editor (PH66).
        public var seen = false
        /// Changed since it was last exported (PH68).
        public var changedSinceExport = false
        public var exported = false

        public var name: String { url.lastPathComponent }
    }

    /// What adding found (PH60).
    public struct AddReport: Sendable, Equatable {
        public var added = 0
        public var alreadyThere = 0
        /// Files that aren't photographs this app reads, with the reason.
        public var skipped: [String] = []
    }

    /// The questions Export All may ask (PH65, PH66).
    public enum Question: Equatable, Sendable {
        case unseen([String])
        case taken([String])
    }

    public enum Answer: Sendable {
        case exportUnseen, keepBoth, replace, skipTaken, cancel
    }

    public struct Progress: Equatable, Sendable {
        public let index: Int, total: Int, name: String
    }

    public struct Summary: Sendable {
        public var exported: [String] = []                 // photograph names
        public var failed: [(name: String, reason: String)] = []
        public var skipped: [String] = []
        public var renumbered: [String] = []              // got " 2" etc. within the batch
        public var warnings = 0
        public var stopped = false
        public var files = 0
    }

    public private(set) var entries: [Entry] = []
    /// The photograph in the editor.
    public private(set) var editingID: UUID?
    public let editor: EditorSession
    public private(set) var lastAdd: AddReport?
    public private(set) var isAdding = false
    public private(set) var question: Question?
    public private(set) var progress: Progress?
    public private(set) var summary: Summary?

    private var plan: [(id: UUID, copy: Int)] = []
    private var stopRequested = false

    public init(editor: EditorSession = EditorSession()) {
        self.editor = editor
        editor.onEdit = { [weak self] c in self?.recordEdit(c) }
        editor.onExported = { [weak self] in self?.markExported(self?.editingID) }
    }

    public var settings: EditorSession.Settings {
        get { editor.settings }
        set { editor.settings = newValue }
    }

    public var isExporting: Bool { progress != nil }

    // MARK: Adding (PH60, PH61)

    /// Adds files and the photographs directly inside folders.
    @discardableResult
    public func add(_ urls: [URL]) async -> AddReport {
        isAdding = true
        defer { isAdding = false }
        var report = AddReport()
        let fm = FileManager.default
        var files = [URL]()
        for url in urls {
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { continue }
            if isDir.boolValue {
                let inside = (try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isRegularFileKey],
                                                          options: [.skipsHiddenFiles])) ?? []
                files += inside.filter { (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true }
            } else {
                files.append(url)
            }
        }
        var known = Set(entries.map { $0.url.standardizedFileURL.path })
        var fresh = [URL]()
        for f in files {
            let path = f.standardizedFileURL.path
            if known.contains(path) { report.alreadyThere += 1; continue }
            known.insert(path)
            fresh.append(f)
        }
        fresh.sort { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }

        let newEntries = fresh.map { Entry(url: $0) }
        entries += newEntries

        // Read each one's header and thumbnail, two at a time.
        await withTaskGroup(of: (UUID, Result<Importer.Probe, Error>).self) { group in
            var pending = newEntries[...]
            func next() {
                guard let e = pending.popFirst() else { return }
                let url = e.url, id = e.id
                group.addTask { (id, Result { try Importer.probe(url) }) }
            }
            next(); next()
            for await (id, result) in group {
                switch result {
                case .success(let p): finishProbe(id, p)
                case .failure(let error): report.skipped += failProbe(id, error)
                }
                next()
            }
        }
        report.added = newEntries.count - report.skipped.count
        lastAdd = report
        return report
    }

    private func finishProbe(_ id: UUID, _ p: Importer.Probe) {
        guard let i = index(id) else { return }
        entries[i].state = .ready
        entries[i].kind = p.kind
        entries[i].uprightWidth = p.uprightWidth
        entries[i].uprightHeight = p.uprightHeight
        entries[i].thumbnail = p.thumbnail
        entries[i].composition = Composition(uprightWidth: p.uprightWidth, height: p.uprightHeight)
    }

    /// Not a photograph at all: dropped from the queue and listed. A damaged
    /// or too-large photograph stays, marked (PH61).
    private func failProbe(_ id: UUID, _ error: Error) -> [String] {
        guard let i = index(id) else { return [] }
        switch error as? ImportError {
        case .notAnImage, .unsupported, .empty, .missing, .none:
            let e = entries.remove(at: i)
            return ["\(e.name): \(Self.reason(error))"]
        case .damaged, .tooLarge:
            entries[i].state = .failed(Self.reason(error))
            return []
        }
    }

    /// The reason without the file name in front (the row shows the name).
    static func reason(_ error: Error) -> String { reason("\(error)") }

    static func reason(_ text: String) -> String {
        guard let colon = text.firstIndex(of: ":") else { return text }
        return text[text.index(after: colon)...].trimmingCharacters(in: .whitespaces)
    }

    // MARK: Selecting and editing (PH59, PH62)

    /// Opens a photograph in the editor, framed as it was left.
    public func select(_ id: UUID?) async {
        guard id != editingID else { return }
        editingID = id
        guard let id, let i = index(id), entries[i].state == .ready else {
            editor.close()
            return
        }
        entries[i].seen = true
        let ok = await editor.open(entries[i].url, composition: entries[i].composition)
        guard editingID == id, let j = index(id) else { return }
        if !ok {
            entries[j].state = .failed(editor.message.map { Self.reason($0.detail) } ?? "it can't be read")
            editor.message = nil
            editor.close()
        }
    }

    private func recordEdit(_ c: Composition) {
        guard let id = editingID, let i = index(id) else { return }
        entries[i].composition = c
        entries[i].changedSinceExport = true
    }

    private func markExported(_ id: UUID?) {
        guard let id, let i = index(id) else { return }
        entries[i].exported = true
        entries[i].changedSinceExport = false
    }

    /// Removes photographs from the queue, never from the disk.
    public func remove(_ ids: Set<UUID>) {
        if let e = editingID, ids.contains(e) {
            editingID = nil
            editor.close()
        }
        entries.removeAll { ids.contains($0.id) }
    }

    public func removeAll() { remove(Set(entries.map(\.id))) }

    /// Whether a photograph's crops are too small for its outputs (PH14),
    /// worked out from its framing alone, without rendering.
    public func isSmall(_ e: Entry) -> Bool {
        guard let c = e.composition, e.state == .ready else { return false }
        let w = e.uprightWidth, h = e.uprightHeight
        let need = PrintProfile(orientation: c.orientation, resolution: settings.resolution).pixels
        let p = c.printRect(uprightWidth: w, height: h), s = c.screenRect(uprightWidth: w, height: h)
        let printSmall = settings.outputs.contains(.print) && (p.width < need.width || p.height < need.height)
        let screenSmall = !settings.outputs.isDisjoint(with: [.screen, .macPaint])
            && (s.width < ScreenImage.width || s.height < ScreenImage.height)
        return printSmall || screenSmall
    }

    /// Photographs with framing changed and not exported (PH68).
    public var unexportedChanges: Int { entries.filter(\.changedSinceExport).count }

    // MARK: Export All (PH64–PH66)

    private var exportable: [Entry] { entries.filter { $0.state == .ready && $0.composition != nil } }

    /// Starts Export All: may stop to ask a question first.
    public func exportAll() async {
        guard !isExporting else { return }
        summary = nil
        guard settings.destination != nil, !settings.outputs.isEmpty, !exportable.isEmpty else {
            editor.message = .init(title: "Nothing to export yet.",
                                   detail: "Add photographs, tick at least one file and choose a folder.")
            return
        }
        // Already exported once with your agreement: not asked about again.
        let unseen = exportable.filter { !$0.seen && !$0.exported }.map(\.name)
        if !unseen.isEmpty {
            question = .unseen(unseen)
            return
        }
        await planAndRun()
    }

    public func answer(_ a: Answer) async {
        let asked = question
        question = nil
        switch (asked, a) {
        case (.unseen, .exportUnseen): await planAndRun()
        case (.taken, .keepBoth): await run(.keepBoth, skip: [])
        case (.taken, .replace): await run(.replace, skip: [])
        case (.taken(let names), .skipTaken): await run(.stop, skip: Set(names))
        default: plan = []
        }
    }

    /// Stops after the photograph being exported.
    public func stop() { stopRequested = true }

    /// Names for the whole batch first (PH65): the same name twice in the
    /// queue is numbered; names already taken in the folder are asked about.
    private func planAndRun() async {
        guard let folder = settings.destination else { return }
        var used = [String: Int]()
        plan = exportable.map { e in
            let key = MacNames.name(for: e.name, extension: "x").lowercased()
            used[key, default: 0] += 1
            return (e.id, used[key]!)
        }
        var taken = [String]()
        for (id, copy) in plan {
            guard let e = entries.first(where: { $0.id == id }) else { continue }
            let exists = settings.outputs.contains { kind in
                FileManager.default.fileExists(atPath: folder.appendingPathComponent(kind.folder)
                    .appendingPathComponent(MacNames.name(for: e.name, extension: kind.fileExtension, copy: copy)).path)
            }
            if exists { taken.append(e.name) }
        }
        if !taken.isEmpty {
            question = .taken(taken)
            return
        }
        await run(.stop, skip: [])
    }

    /// One photograph at a time; a failure is recorded and the batch goes on.
    private func run(_ ifExists: IfExists, skip: Set<String>) async {
        guard let folder = settings.destination else { return }
        let resolution = settings.resolution, kinds = settings.outputs
        var s = Summary()
        stopRequested = false
        let jobs = plan
        plan = []
        for (k, job) in jobs.enumerated() {
            guard let e = entries.first(where: { $0.id == job.id }), let c = e.composition else { continue }
            if skip.contains(e.name) { s.skipped.append(e.name); continue }
            if stopRequested { s.stopped = true; break }
            progress = Progress(index: k + 1, total: jobs.count, name: e.name)
            let url = e.url, copy = job.copy
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    let photo = try Importer.load(url)                      // let go after this photograph (PH67)
                    return try Exporter.export(photo, c, resolution: resolution, kinds: kinds,
                                               to: folder, ifExists: ifExists, firstCopy: copy)
                }.value
                s.exported.append(e.name)
                s.files += result.files.count
                s.warnings += result.warnings.count
                if copy > 1 { s.renumbered.append(e.name) }
                markExported(job.id)
            } catch {
                s.failed.append((e.name, Self.reason(error)))
                if let i = index(job.id), error is ImportError { entries[i].state = .failed(Self.reason(error)) }
            }
        }
        progress = nil
        summary = s
    }

    public func dismissSummary() { summary = nil }

    private func index(_ id: UUID) -> Int? { entries.firstIndex { $0.id == id } }
}
