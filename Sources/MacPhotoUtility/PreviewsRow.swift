import SwiftUI
import MacPhotoKit

/// The two previews, from the real renderers (PH50), side by side and
/// labelled so print and screen can't be confused (specification §4).
struct PreviewsRow: View {
    let session: EditorSession
    @State private var showLarger = false

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            printPreview
            screenPreview
            Spacer(minLength: 0)
        }
        .padding(16)
        .sheet(isPresented: $showLarger) { largerScreen }
    }

    private var printPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Print: 2.5 × 3.5 in").font(.headline)
            ZStack {
                Rectangle().fill(.quaternary)
                if let p = session.printPreview {
                    Image(decorative: Pictures.cgImage(p.image), scale: 1)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .accessibilityLabel("Print preview")
                }
            }
            .frame(width: 250, height: 342)
            Text(printCaption).font(.caption).foregroundStyle(.secondary)
            warnings(session.printWarnings)
        }
        .frame(width: 250, alignment: .leading)
    }

    private var printCaption: String {
        guard let p = session.printPreview else { return "8-bit grey" }
        return "\(p.image.width) × \(p.image.height) px · \(p.profile.resolution.ppi) PPI · 8-bit grey"
    }

    private var screenPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Mac Plus screen: 512 × 342").font(.headline)
                Spacer()
                Button("Larger…") { showLarger = true }
                    .disabled(session.screenPreview == nil)
                    .help("Show the screen image at 2×")
            }
            ZStack {
                Rectangle().fill(.quaternary)
                if let s = session.screenPreview {
                    Image(decorative: Pictures.cgImage(s.bits), scale: 1)
                        .interpolation(.none)                       // square pixels, exactly
                        .accessibilityLabel("Mac Plus screen preview, 1-bit")
                }
            }
            .frame(width: 512, height: 342)
            Text("1-bit Atkinson, one Plus pixel per point, as it will look on the Plus")
                .font(.caption).foregroundStyle(.secondary)
            toneControls
            warnings(session.screenWarnings)
        }
        .frame(width: 512, alignment: .leading)
    }

    /// Brightness and contrast for the screen image only (PH57).
    private var toneControls: some View {
        let tone = session.composition?.screenTone ?? .neutral
        return HStack(spacing: 10) {
            toneSlider("Brightness", tone.brightness) { ScreenTone(brightness: $0, contrast: tone.contrast) }
            toneSlider("Contrast", tone.contrast) { ScreenTone(brightness: tone.brightness, contrast: $0) }
            Button("Normal") { session.setScreenTone(.neutral) }
                .disabled(tone == .neutral)
                .help("Brightness and contrast back to 0")
        }
        .disabled(session.photo == nil)
        .help("Changes the screen image only; the print is never affected.")
    }

    private func toneSlider(_ title: String, _ value: Int, _ make: @escaping (Int) -> ScreenTone) -> some View {
        HStack(spacing: 6) {
            Text(title).font(.callout)
            Slider(value: Binding(get: { Double(value) },
                                  set: { session.setScreenTone(make(Int($0.rounded()))) }),
                   in: -100...100)
                .frame(minWidth: 110)
                .accessibilityLabel("Screen \(title.lowercased())")
                .accessibilityValue("\(value)")
            Text(value > 0 ? "+\(value)" : "\(value)")
                .font(.callout.monospacedDigit())
                .frame(width: 36, alignment: .trailing)
        }
    }

    private var largerScreen: some View {
        VStack(spacing: 12) {
            if let s = session.screenPreview {
                Image(decorative: Pictures.cgImage(s.bits), scale: 1)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 1024, height: 684)
            }
            HStack {
                Text("The Mac Plus screen at 2×").foregroundStyle(.secondary)
                Spacer()
                Button("Done") { showLarger = false }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
    }

    @ViewBuilder
    private func warnings(_ list: [RenderWarning]) -> some View {
        ForEach(Array(list.enumerated()), id: \.offset) { _, w in
            Label(w.description, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
