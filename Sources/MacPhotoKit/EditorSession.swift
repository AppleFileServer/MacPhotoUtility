import Foundation
import Observation

/// Everything the window shows and does for one photograph (PH46): the
/// photograph, its composition, the settings, the previews and the export.
/// The window only draws this and passes gestures to it, so all of it can
/// be tested without a window. Slow work runs off the main actor.
@MainActor @Observable
public final class EditorSession {
    /// What's remembered between launches (PH53).
    public struct Settings: Equatable, Sendable {
        public var resolution: PrintResolution = .standard
        public var outputs: Set<OutputKind> = [.print, .screen]       // MacPaint rarely (PH15)
        public var destination: URL?
    }

    /// A message for the user: what happened, in words (PH52).
    public struct Message: Equatable, Sendable, Identifiable {
        public let id = UUID()
        public let title: String
        public let detail: String
        public init(title: String, detail: String) {
            self.title = title
            self.detail = detail
        }
        public static func == (a: Message, b: Message) -> Bool { a.title == b.title && a.detail == b.detail }
    }

    public private(set) var photo: ImportedPhoto?
    /// The upright photograph reduced for drawing (PH49).
    public private(set) var working: GreyImage?
    /// The working copy turned as the composition says: what the editor draws.
    public private(set) var turnedWorking: GreyImage?
    public private(set) var composition: Composition?
    public var editing: CropKind = .print

    public var settings: Settings {
        didSet {
            guard settings != oldValue else { return }
            saveSettings()
            onSettingsChanged?()
            if settings.resolution != oldValue.resolution { schedulePreviews() }
        }
    }

    public private(set) var printPreview: PrintRenderer.Result?
    public private(set) var screenPreview: ScreenRenderer.Result?
    public private(set) var isOpening = false
    public private(set) var isRendering = false
    public private(set) var isExporting = false
    /// The files of the last export, with its warnings.
    public private(set) var lastExport: (files: [ExportedFile], warnings: [RenderWarning])?
    /// Names already taken, waiting for Replace / Keep Both / Cancel (PH51).
    public private(set) var conflict: [String]?
    public var message: Message?

    private let defaults: UserDefaults
    private let previewDelay: Duration
    private var previewTask: Task<Void, Never>?
    private var generation = 0

    public init(defaults: UserDefaults = .standard, previewDelay: Duration = .milliseconds(200)) {
        self.defaults = defaults
        self.previewDelay = previewDelay
        settings = Settings()
        loadSettings()
    }

    // MARK: Opening

    /// Called with the composition after every edit, so the queue can keep
    /// each photograph's own (PH59).
    public var onEdit: ((Composition) -> Void)?
    /// Called after the photograph in hand has been exported, with what was written.
    public var onExported: ((_ files: [ExportedFile], _ warnings: [RenderWarning]) -> Void)?
    /// Called when the shared settings change (a project's unsaved changes).
    public var onSettingsChanged: (() -> Void)?
    private var openGeneration = 0

    /// Opens a photograph, framed as `composition` says, or with the
    /// defaults (PH26). Returns whether it opened.
    @discardableResult
    public func open(_ url: URL, composition saved: Composition? = nil) async -> Bool {
        openGeneration += 1
        let mine = openGeneration
        isOpening = true
        defer { if openGeneration == mine { isOpening = false } }
        do {
            let (photo, working) = try await Task.detached(priority: .userInitiated) {
                let p = try Importer.load(url)
                return (p, Resampler.reduced(p.image))
            }.value
            // A later open has started since: this one is no longer wanted.
            guard openGeneration == mine else { return false }
            self.photo = photo
            self.working = working
            let c = saved ?? Composition(uprightWidth: photo.image.width, height: photo.image.height)
            composition = c
            turnedWorking = c.quarterTurns == 0 ? working : working.turned(c.quarterTurns)
            editing = .print
            printPreview = nil
            screenPreview = nil
            lastExport = nil
            schedulePreviews()
            return true
        } catch {
            guard openGeneration == mine else { return false }
            message = Message(title: "The photograph couldn't be opened.", detail: "\(error)")
            return false
        }
    }

    public func close() {
        previewTask?.cancel()
        isRendering = false
        photo = nil; working = nil; turnedWorking = nil; composition = nil
        printPreview = nil; screenPreview = nil; lastExport = nil; conflict = nil
    }

    // MARK: Editing (PH48)

    private func edit(_ change: (inout Composition, Int, Int) -> Void) {
        guard var c = composition, let p = photo else { return }
        change(&c, p.image.width, p.image.height)
        guard c != composition else { return }
        if c.quarterTurns != composition?.quarterTurns { turnedWorking = working?.turned(c.quarterTurns) }
        composition = c
        onEdit?(c)
        schedulePreviews()
    }

    /// Moves the crop being edited by fractions of the turned photograph.
    public func move(dx: Double, dy: Double) {
        let k = editing
        edit { $0.move(k, dx: dx, dy: dy, uprightWidth: $1, height: $2) }
    }

    /// Resizes the crop being edited by one corner, keeping its shape.
    public func resize(corner: Corner, to point: (x: Double, y: Double)) {
        let k = editing
        edit { $0.resize(k, corner: corner, to: point, uprightWidth: $1, height: $2) }
    }

    public func setZoom(_ zoom: Double) {
        let k = editing
        edit { $0.setZoom(k, zoom, uprightWidth: $1, height: $2) }
    }

    public func turn(by quarters: Int) {
        edit { c, w, h in c.turn(by: quarters); c.clampCrops(uprightWidth: w, height: h) }
    }

    public func setOrientation(_ o: Orientation) {
        edit { c, w, h in c.setOrientation(o); c.clampCrops(uprightWidth: w, height: h) }
    }

    /// The screen image's brightness and contrast (PH57); the print is untouched.
    public func setScreenTone(_ tone: ScreenTone) {
        edit { c, _, _ in c.screenTone = tone }
    }

    public func resetCrop() {
        let k = editing
        edit { $0.reset(k, uprightWidth: $1, height: $2) }
    }

    /// The turned working copy's size, for the editor's drawing.
    public var turnedWorkingSize: (width: Int, height: Int)? {
        guard let w = working, let c = composition else { return nil }
        return c.turnedSize(uprightWidth: w.width, height: w.height)
    }

    // MARK: Previews (PH50)

    private func schedulePreviews() {
        previewTask?.cancel()
        guard let photo, let composition else { return }
        generation += 1
        let mine = generation, delay = previewDelay, resolution = settings.resolution
        let image = photo.image
        isRendering = true
        previewTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            async let p = Task.detached(priority: .userInitiated) {
                PrintRenderer.render(image, composition, resolution: resolution)
            }.value
            async let s = Task.detached(priority: .userInitiated) {
                ScreenRenderer.render(image, composition)
            }.value
            let (print, screen) = await (p, s)
            guard let self, !Task.isCancelled, self.generation == mine else { return }
            self.printPreview = print
            self.screenPreview = screen
            self.isRendering = false
        }
    }

    /// Waits for the previews in hand to finish (for tests and export).
    public func previewsSettled() async {
        await previewTask?.value
    }

    /// The warnings that apply to each output now (PH52).
    public var printWarnings: [RenderWarning] { printPreview?.warnings ?? [] }
    public var screenWarnings: [RenderWarning] { screenPreview?.warnings ?? [] }

    // MARK: Export (PH51)

    public var canExport: Bool {
        photo != nil && !settings.outputs.isEmpty && settings.destination != nil && !isExporting
    }

    /// Exports, stopping to ask if a name is taken.
    public func export() async {
        await runExport(.stop)
    }

    /// The answer to the conflict question: replace, keep both, or nil to cancel.
    public func resolveConflict(_ choice: IfExists?) async {
        conflict = nil
        guard let choice else { return }
        await runExport(choice)
    }

    private func runExport(_ ifExists: IfExists) async {
        guard let photo, let composition, let folder = settings.destination, !settings.outputs.isEmpty else {
            message = Message(title: "Nothing to export yet.",
                              detail: "Open a photograph, tick at least one file and choose a folder.")
            return
        }
        isExporting = true
        defer { isExporting = false }
        let resolution = settings.resolution, kinds = settings.outputs
        do {
            let result = try await Task.detached(priority: .userInitiated) {
                try Exporter.export(photo, composition, resolution: resolution, kinds: kinds,
                                    to: folder, ifExists: ifExists)
            }.value
            lastExport = result
            onExported?(result.files, result.warnings)
        } catch ExportError.exists(let names) {
            conflict = names
        } catch {
            message = Message(title: "Nothing was exported.", detail: "\(error)")
        }
    }

    // MARK: Settings (PH53)

    private enum Key {
        static let ppi = "printPPI", outputs = "outputs", destination = "destinationPath"
    }

    private func loadSettings() {
        var s = Settings()
        if let r = PrintResolution(rawValue: defaults.integer(forKey: Key.ppi)) { s.resolution = r }
        if let o = defaults.stringArray(forKey: Key.outputs) { s.outputs = Set(o.compactMap(OutputKind.init)) }
        if let path = defaults.string(forKey: Key.destination) { s.destination = URL(fileURLWithPath: path) }
        settings = s
    }

    private func saveSettings() {
        defaults.set(settings.resolution.rawValue, forKey: Key.ppi)
        defaults.set(settings.outputs.map(\.rawValue).sorted(), forKey: Key.outputs)
        defaults.set(settings.destination?.path, forKey: Key.destination)
    }
}
