import AppKit
import SwiftUI
import MacPhotoKit

/// The composition editor (PH48): the whole turned photograph, the crop
/// being edited drawn over it with everything outside it dimmed, and the
/// other crop as a thin outline. All the arithmetic is the session's; this
/// view only turns points into fractions of the picture.
struct CompositionEditor: View {
    @Bindable var session: EditorSession
    @State private var dragLast: CGSize = .zero
    @State private var pinchStart: Double?
    @State private var hovering = false
    @State private var scrollMonitor: Any?
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            GeometryReader { geo in
                if let picture = session.turnedWorking, let c = session.composition, let p = session.photo {
                    let frame = fitted(picture.width, picture.height, in: geo.size)
                    canvas(picture, c, p, frame)
                } else {
                    placeholder
                }
            }
            .padding(16)
        }
        .onAppear { installScrollMonitor() }
        .onDisappear { if let m = scrollMonitor { NSEvent.removeMonitor(m) } }
    }

    // MARK: The controls

    private var toolbar: some View {
        HStack(spacing: 14) {
            Picker("Crop", selection: $session.editing) {
                Text("Print crop").tag(CropKind.print)
                Text("Screen crop").tag(CropKind.screen)
            }
            .pickerStyle(.segmented)
            .frame(width: 230)
            .accessibilityLabel("Which crop to edit")

            Button { session.turn(by: -1) } label: { Image(systemName: "rotate.left") }
                .help("Turn left a quarter (⌘[)")
                .accessibilityLabel("Turn left")
            Button { session.turn(by: 1) } label: { Image(systemName: "rotate.right") }
                .help("Turn right a quarter (⌘])")
                .accessibilityLabel("Turn right")

            if session.editing == .print {
                Picker("Print", selection: Binding(
                    get: { session.composition?.orientation ?? .portrait },
                    set: { session.setOrientation($0) })) {
                    Text("Portrait").tag(Orientation.portrait)
                    Text("Landscape").tag(Orientation.landscape)
                }
                .pickerStyle(.segmented)
                .frame(width: 190)
                .accessibilityLabel("Print orientation")
            }

            Spacer()
            Image(systemName: "minus.magnifyingglass").foregroundStyle(.secondary)
            Slider(value: Binding(
                get: { log2(session.composition?.crop(session.editing).zoom ?? 1) },
                set: { session.setZoom(pow(2, $0)) }), in: 0...3)
                .frame(minWidth: 90, maxWidth: 160)
                .accessibilityLabel("Zoom")
                .accessibilityValue("\((session.composition?.crop(session.editing).zoom ?? 1).formatted(.number.precision(.fractionLength(1)))) times")
            Image(systemName: "plus.magnifyingglass").foregroundStyle(.secondary)
            Button("Reset") { session.resetCrop() }
                .fixedSize()
                .help("Back to centred, full size (⌘0)")
        }
        .disabled(session.photo == nil)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var placeholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "photo").font(.system(size: 44)).foregroundStyle(.tertiary)
            Text("No photograph open").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: The picture and its crops

    private func canvas(_ picture: GreyImage, _ c: Composition, _ p: ImportedPhoto, _ frame: CGRect) -> some View {
        let w = p.image.width, h = p.image.height
        let other: CropKind = session.editing == .print ? .screen : .print
        let mine = rect(c.fractions(session.editing, uprightWidth: w, height: h), in: frame)
        let theirs = rect(c.fractions(other, uprightWidth: w, height: h), in: frame)
        return ZStack(alignment: .topLeading) {
            Image(decorative: Pictures.cgImage(picture), scale: 1)
                .resizable()
                .interpolation(.high)
                .frame(width: frame.width, height: frame.height)
                .offset(x: frame.minX, y: frame.minY)
            // Dim everything outside the crop being edited (specification §5).
            Path { path in
                path.addRect(frame)
                path.addRect(mine)
            }
            .fill(Color.black.opacity(0.55), style: FillStyle(eoFill: true))
            Rectangle()
                .path(in: theirs)
                .stroke(Color.yellow.opacity(0.8), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            Rectangle().path(in: mine).stroke(Color.white, lineWidth: 2)
            Rectangle().path(in: mine.insetBy(dx: -1, dy: -1)).stroke(Color.black.opacity(0.6), lineWidth: 1)
            Text(session.editing == .print ? "Print" : "Screen")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(.white, in: RoundedRectangle(cornerRadius: 3))
                .foregroundStyle(.black)
                .offset(x: mine.minX + 4, y: mine.minY + 4)
            ForEach(Corner.allCases, id: \.self) { corner in
                handle(corner, mine, frame)
            }
        }
        .coordinateSpace(.named("canvas"))
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 1)
            .onChanged { v in
                let d = CGSize(width: v.translation.width - dragLast.width,
                               height: v.translation.height - dragLast.height)
                dragLast = v.translation
                session.move(dx: d.width / frame.width, dy: d.height / frame.height)
            }
            .onEnded { _ in dragLast = .zero })
        .simultaneousGesture(MagnifyGesture()
            .onChanged { v in
                let start = pinchStart ?? c.crop(session.editing).zoom
                pinchStart = start
                session.setZoom(start * v.magnification)
            }
            .onEnded { _ in pinchStart = nil })
        .onHover { hovering = $0 }
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .onKeyPress(.tab) { session.editing = session.editing == .print ? .screen : .print; return .handled }
        .onKeyPress(.leftArrow) { session.move(dx: -0.01, dy: 0); return .handled }
        .onKeyPress(.rightArrow) { session.move(dx: 0.01, dy: 0); return .handled }
        .onKeyPress(.upArrow) { session.move(dx: 0, dy: -0.01); return .handled }
        .onKeyPress(.downArrow) { session.move(dx: 0, dy: 0.01); return .handled }
        .onTapGesture { focused = true }
        .accessibilityElement()
        .accessibilityLabel("\(session.editing == .print ? "Print" : "Screen") crop over the photograph")
        .accessibilityHint("Drag to move the crop; arrow keys nudge it; Tab switches crops.")
    }

    /// A corner handle (PH58): dragging it resizes the crop, its shape kept
    /// and the opposite corner still. A child's gesture comes before the
    /// canvas's, so grabbing a handle never moves the crop.
    private func handle(_ corner: Corner, _ crop: CGRect, _ frame: CGRect) -> some View {
        let point: CGPoint, pointer: FrameResizePosition
        switch corner {
        case .topLeft: point = CGPoint(x: crop.minX, y: crop.minY); pointer = .topLeading
        case .topRight: point = CGPoint(x: crop.maxX, y: crop.minY); pointer = .topTrailing
        case .bottomLeft: point = CGPoint(x: crop.minX, y: crop.maxY); pointer = .bottomLeading
        case .bottomRight: point = CGPoint(x: crop.maxX, y: crop.maxY); pointer = .bottomTrailing
        }
        return Rectangle()
            .fill(.white)
            .overlay(Rectangle().stroke(.black, lineWidth: 1))
            .frame(width: 10, height: 10)
            .frame(width: 22, height: 22)                    // easier to grab than to see
            .contentShape(Rectangle())
            .position(point)
            .pointerStyle(.frameResize(position: pointer))
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("canvas"))
                .onChanged { v in
                    session.resize(corner: corner, to: ((v.location.x - frame.minX) / frame.width,
                                                        (v.location.y - frame.minY) / frame.height))
                })
            .accessibilityHidden(true)                       // the zoom slider does the same
    }

    /// The picture fitted into the space, centred.
    private func fitted(_ w: Int, _ h: Int, in size: CGSize) -> CGRect {
        let s = min(size.width / CGFloat(w), size.height / CGFloat(h))
        let fw = CGFloat(w) * s, fh = CGFloat(h) * s
        return CGRect(x: (size.width - fw) / 2, y: (size.height - fh) / 2, width: fw, height: fh)
    }

    private func rect(_ f: (x: Double, y: Double, width: Double, height: Double), in frame: CGRect) -> CGRect {
        CGRect(x: frame.minX + f.x * frame.width, y: frame.minY + f.y * frame.height,
               width: f.width * frame.width, height: f.height * frame.height)
    }

    /// The scroll wheel zooms while the pointer is over the picture.
    private func installScrollMonitor() {
        guard scrollMonitor == nil else { return }
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            guard hovering, let c = session.composition else { return event }
            let zoom = c.crop(session.editing).zoom * exp(-event.scrollingDeltaY * (event.hasPreciseScrollingDeltas ? 0.005 : 0.05))
            session.setZoom(zoom)
            return nil
        }
    }
}
