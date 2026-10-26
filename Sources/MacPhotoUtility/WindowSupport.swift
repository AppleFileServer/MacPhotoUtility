import AppKit
import SwiftUI

// The window's AppKit side, as the Macintosh Transfer Utility does it: find
// the NSWindow, and ask before it closes with unsaved changes (PH72).

/// Hands over the NSWindow a SwiftUI view is in, once it's in one.
struct WindowFinder: NSViewRepresentable {
    let found: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView { Finder(found: found) }
    func updateNSView(_ view: NSView, context: Context) {}

    final class Finder: NSView {
        let found: (NSWindow) -> Void
        init(found: @escaping (NSWindow) -> Void) {
            self.found = found
            super.init(frame: .zero)
        }
        required init?(coder: NSCoder) { fatalError("not used") }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let window { found(window) }
        }
    }
}

/// Stands in front of a window's delegate (SwiftUI's) to ask before the
/// window closes; everything else is passed on to the real delegate.
final class CloseGuard: NSObject, NSWindowDelegate {
    weak var window: NSWindow?
    weak var original: NSWindowDelegate?
    let shouldClose: @MainActor () -> Bool

    @MainActor
    init(window: NSWindow, shouldClose: @escaping @MainActor () -> Bool) {
        self.window = window
        self.original = window.delegate
        self.shouldClose = shouldClose
        super.init()
        window.delegate = self
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        let allowed = MainActor.assumeIsolated { shouldClose() }
        guard allowed else { return false }
        return original?.windowShouldClose?(sender) ?? true
    }

    override func responds(to aSelector: Selector!) -> Bool {
        super.responds(to: aSelector) || (original?.responds(to: aSelector) ?? false)
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        original?.responds(to: aSelector) == true ? original : super.forwardingTarget(for: aSelector)
    }
}
