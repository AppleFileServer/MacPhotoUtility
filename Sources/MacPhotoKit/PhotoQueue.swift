import Foundation
import Observation

/// The photographs being worked on, in order (Phase 4; PH59–PH68): each
/// with its own framing, status and thumbnail, sharing one set of output
/// settings. The editor edits the selected one; Export All exports them
/// one at a time. Saved and reopened as a project (Phase 5; PH70–PH79).
/// Tested without a window.
@MainActor @Observable
public final class PhotoQueue {
    public enum State: Equatable, Sendable {
        case reading
        case ready
        case failed(String)
        /// Not found when the project was opened (PH73).
        case missing
    }

    public struct Entry: Identifiable, Sendable {
        public let id = UUID()
        public var url: URL
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
        /// Size and SHA-256, to know it again (PH73, PH75).
        public var fingerprint: Fingerprint?
        /// A Finder bookmark, which follows the file if it moves.
        public var bookmark: Data?
        /// Relinked to a file with different content, on purpose (PH74).
        public var acceptedDifferentFile = false
        public var history: [ExportRecord] = []

        public var name: String { url.lastPathComponent }

        init(url: URL) { self.url = url }
    }

    /// What adding found (PH60).
    public struct AddReport: Sendable, Equatable {
        public var added = 0
        public var alreadyThere = 0
        /// Files that aren't photographs this app reads, with the reason.
        public var skipped: [String] = []
    }

    /// What opening a project found (PH73).
    public struct OpenReport: Sendable, Equatable {
        public var moved: [String] = []
        public var missing: [String] = []
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

    /// Relinking a photograph to a file (PH74).
    public enum RelinkOutcome: Equatable, Sendable {
        case linked
        /// The file's content isn't the photograph's: not used unless confirmed.
        case differs
        case unreadable(String)
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

    /// The project's file, nil until it's saved (PH71).
    public private(set) var projectURL: URL?
    /// Changes since the project was last saved or opened (PH72).
    public private(set) var isDirty = false
    private var created = ISO8601DateFormatter().string(from: Date())

    private var plan: [(id: UUID, copy: Int)] = []
    private var stopRequested = false

    public init(editor: EditorSession = EditorSession()) {
        self.editor = editor
        editor.onEdit = { [weak self] c in self?.recordEdit(c) }
        editor.onExported = { [weak self] files, warnings in
            guard let self, let id = self.editingID, let folder = self.settings.destination else { return }
            self.recordExport(id, folder: folder, files: files, warnings: warnings)
        }
        editor.onSettingsChanged = { [weak self] in self?.isDirty = true }
    }

    public var settings: EditorSession.Settings {
        get { editor.settings }
        set { editor.settings = newValue }
    }

    public var isExporting: Bool { progress != nil }

    /// The window's title: the project's name, or Untitled.
    public var title: String { projectURL?.deletingPathExtension().lastPathComponent ?? "Untitled" }

    // MARK: Adding (PH60, PH61, PH75)

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
        report.skipped = await readAll(newEntries.map(\.id), fingerprint: true)
        report.added = newEntries.count - report.skipped.count
        if report.added > 0 { isDirty = true }
        lastAdd = report
        return report
    }

    /// What reading one photograph on adding or reopening finds.
    private struct Read: Sendable {
        let probe: Importer.Probe
        let fingerprint: Fingerprint?
        let bookmark: Data?
    }

    /// Reads each one's header and thumbnail (and, when added, fingerprint
    /// and bookmark), two at a time. Returns the files dropped as not
    /// photographs.
    private func readAll(_ ids: [UUID], fingerprint: Bool) async -> [String] {
        var skipped = [String]()
        let jobs = ids.compactMap { id in index(id).map { (id, entries[$0].url) } }
        await withTaskGroup(of: (UUID, Result<Read, Error>).self) { group in
            var pending = jobs[...]
            func next() {
                guard let (id, url) = pending.popFirst() else { return }
                group.addTask {
                    (id, Result {
                        let p = try Importer.probe(url)
                        return Read(probe: p,
                                    fingerprint: fingerprint ? try Fingerprint.of(url) : nil,
                                    bookmark: fingerprint ? try? url.bookmarkData() : nil)
                    })
                }
            }
            next(); next()
            for await (id, result) in group {
                switch result {
                case .success(let r): finishRead(id, r)
                case .failure(let error): skipped += failRead(id, error)
                }
                next()
            }
        }
        return skipped
    }

    private func finishRead(_ id: UUID, _ r: Read) {
        guard let i = index(id) else { return }
        let p = r.probe
        entries[i].state = .ready
        entries[i].kind = p.kind
        entries[i].uprightWidth = p.uprightWidth
        entries[i].uprightHeight = p.uprightHeight
        entries[i].thumbnail = p.thumbnail
        if entries[i].composition == nil {
            entries[i].composition = Composition(uprightWidth: p.uprightWidth, height: p.uprightHeight)
        }
        if let f = r.fingerprint { entries[i].fingerprint = f }
        if let b = r.bookmark { entries[i].bookmark = b }
    }

    /// Not a photograph at all: dropped from the queue and listed. A damaged
    /// or too-large photograph stays, marked (PH61).
    private func failRead(_ id: UUID, _ error: Error) -> [String] {
        guard let i = index(id) else { return [] }
        switch error as? ImportError {
        case .notAnImage, .unsupported, .empty, .missing, .none:
            // A photograph from a project that is no longer a picture stays,
            // marked, rather than vanishing from the project.
            if entries[i].fingerprint != nil && entries[i].composition != nil {
                entries[i].state = .failed(Self.reason(error))
                return []
            }
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
        isDirty = true
    }

    /// Records an export in the photograph's history (PH76).
    private func recordExport(_ id: UUID, folder: URL, files: [ExportedFile], warnings: [RenderWarning]) {
        guard let i = index(id) else { return }
        entries[i].exported = true
        entries[i].changedSinceExport = false
        entries[i].history.append(ExportRecord(
            folder: folder, files: files,
            ppi: files.contains { $0.kind == .print } ? settings.resolution.ppi : nil,
            warnings: warnings.map(\.description)))
        isDirty = true
    }

    /// Removes photographs from the queue, never from the disk.
    public func remove(_ ids: Set<UUID>) {
        if let e = editingID, ids.contains(e) {
            editingID = nil
            editor.close()
        }
        let before = entries.count
        entries.removeAll { ids.contains($0.id) }
        if entries.count != before { isDirty = true }
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

    /// Photographs with framing changed and not exported.
    public var unexportedChanges: Int { entries.filter(\.changedSinceExport).count }

    // MARK: Projects (PH70–PH79)

    /// The project as it would be saved.
    public func projectFile() -> ProjectFile {
        ProjectFile(
            created: created,
            modified: ISO8601DateFormatter().string(from: Date()),
            settings: .init(ppi: settings.resolution.ppi,
                            outputs: OutputKind.allCases.filter(settings.outputs.contains).map(\.rawValue),
                            destination: settings.destination?.path),
            photographs: entries.map { e in
                var problem: String?
                if case .failed(let why) = e.state { problem = why }
                return .init(path: e.url.path, bookmark: e.bookmark, fingerprint: e.fingerprint, kind: e.kind,
                             uprightWidth: e.uprightWidth, uprightHeight: e.uprightHeight,
                             composition: e.composition, seen: e.seen, exported: e.exported,
                             changedSinceExport: e.changedSinceExport, problem: problem,
                             acceptedDifferentFile: e.acceptedDifferentFile, history: e.history)
            })
    }

    /// Saves the project to `url` (PH72).
    public func save(to url: URL) throws {
        try projectFile().write(to: url)
        projectURL = url
        isDirty = false
    }

    /// Starts an empty project with the settings last used (PH78).
    public func newProject() {
        editingID = nil
        editor.close()
        entries = []
        lastAdd = nil
        summary = nil
        projectURL = nil
        created = ISO8601DateFormatter().string(from: Date())
        isDirty = false
    }

    /// Opens a project: each photograph is found again by its bookmark or
    /// its path, and accepted only if its fingerprint matches (PH73).
    @discardableResult
    public func openProject(_ url: URL) async throws -> OpenReport {
        let data: Data
        do { data = try Data(contentsOf: url) }
        catch { throw ProjectFile.Problem.unreadable("the file can't be opened") }
        let file = try ProjectFile.decode(data)

        newProject()
        created = file.created
        var s = settings
        s.resolution = PrintResolution(rawValue: file.settings.ppi) ?? .standard
        s.outputs = Set(file.settings.outputs.compactMap(OutputKind.init))
        s.destination = file.settings.destination.map { URL(fileURLWithPath: $0) }
        settings = s

        entries = file.photographs.map { p in
            var e = Entry(url: URL(fileURLWithPath: p.path))
            e.kind = p.kind
            e.uprightWidth = p.uprightWidth
            e.uprightHeight = p.uprightHeight
            e.composition = p.composition
            e.seen = p.seen
            e.exported = p.exported
            e.changedSinceExport = p.changedSinceExport
            e.fingerprint = p.fingerprint
            e.bookmark = p.bookmark
            e.acceptedDifferentFile = p.acceptedDifferentFile
            e.history = p.history
            e.state = .missing
            return e
        }

        // Find each one again, off the main actor (hashing reads the files).
        var report = OpenReport()
        let wanted = entries.map { ($0.id, $0.url, $0.bookmark, $0.fingerprint) }
        let found = await withTaskGroup(of: (UUID, URL?).self) { group in
            for (id, path, bookmark, fingerprint) in wanted {
                group.addTask { (id, Self.locate(path: path, bookmark: bookmark, fingerprint: fingerprint)) }
            }
            var out = [UUID: URL]()
            for await (id, u) in group { if let u { out[id] = u } }
            return out
        }
        var toRead = [UUID]()
        for i in entries.indices {
            let id = entries[i].id
            if let u = found[id] {
                if u.standardizedFileURL.path != entries[i].url.standardizedFileURL.path {
                    report.moved.append(entries[i].name)
                    entries[i].url = u
                    entries[i].bookmark = try? u.bookmarkData()
                }
                entries[i].state = .reading
                toRead.append(id)
            } else {
                report.missing.append(entries[i].name)
            }
        }
        _ = await readAll(toRead, fingerprint: false)
        projectURL = url
        isDirty = !report.moved.isEmpty            // new locations to save
        return report
    }

    /// Where a saved photograph is now, if anywhere: its bookmark first, then
    /// its path; only a file with the same fingerprint counts (PH73).
    nonisolated static func locate(path: URL, bookmark: Data?, fingerprint: Fingerprint?) -> URL? {
        var candidates = [URL]()
        if let bookmark {
            var stale = false
            if let u = try? URL(resolvingBookmarkData: bookmark, options: [.withoutUI], bookmarkDataIsStale: &stale) {
                candidates.append(u)
            }
        }
        candidates.append(path)
        for u in candidates where FileManager.default.fileExists(atPath: u.path) {
            if matches(u, fingerprint) { return u }
        }
        return nil
    }

    /// The same photograph: same size, then same SHA-256. A project saved
    /// without a fingerprint accepts the file as it is.
    nonisolated static func matches(_ url: URL, _ fingerprint: Fingerprint?) -> Bool {
        guard let fingerprint else { return FileManager.default.fileExists(atPath: url.path) }
        guard Fingerprint.size(url) == fingerprint.bytes else { return false }
        return (try? Fingerprint.of(url)) == fingerprint
    }

    // MARK: Relinking (PH74)

    /// Links a missing photograph to `url`, if it's the same photograph.
    public func relink(_ id: UUID, to url: URL) async -> RelinkOutcome {
        guard let i = index(id) else { return .unreadable("it's no longer in the queue") }
        let fp = entries[i].fingerprint
        let same = await Task.detached { Self.matches(url, fp) }.value
        guard same else { return .differs }
        return await link(id, to: url, acceptingDifferent: false)
    }

    /// Links to a file with different content, because you said so.
    public func relinkAcceptingDifferent(_ id: UUID, to url: URL) async -> RelinkOutcome {
        await link(id, to: url, acceptingDifferent: true)
    }

    private func link(_ id: UUID, to url: URL, acceptingDifferent: Bool) async -> RelinkOutcome {
        guard index(id) != nil else { return .unreadable("it's no longer in the queue") }
        let fp = await Task.detached { try? Fingerprint.of(url) }.value
        guard let fp, let i = index(id) else { return .unreadable("the file can't be read") }
        entries[i].url = url
        entries[i].bookmark = try? url.bookmarkData()
        if acceptingDifferent {
            entries[i].fingerprint = fp
            entries[i].acceptedDifferentFile = true
        }
        entries[i].state = .reading
        isDirty = true
        _ = await readAll([id], fingerprint: false)
        if let j = index(id), case .failed(let why) = entries[j].state { return .unreadable(why) }
        // Selected while it was missing: show it now it's back.
        if editingID == id {
            editingID = nil
            await select(id)
        }
        return .linked
    }

    /// Looks in one folder for every missing photograph: by name, then by
    /// size and fingerprint. Returns how many were found.
    @discardableResult
    public func locate(inFolder folder: URL) async -> Int {
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil,
                                                                  options: [.skipsHiddenFiles])) ?? []
        var found = 0
        for e in entries where e.state == .missing {
            let byName = files.filter { $0.lastPathComponent == e.name }
            let bySize = files.filter { $0.lastPathComponent != e.name && Fingerprint.size($0) == e.fingerprint?.bytes }
            let fp = e.fingerprint
            let match = await Task.detached { (byName + bySize).first { Self.matches($0, fp) } }.value
            if let match, await link(e.id, to: match, acceptingDifferent: false) == .linked { found += 1 }
        }
        return found
    }

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
                recordExport(job.id, folder: folder, files: result.files, warnings: result.warnings)
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
