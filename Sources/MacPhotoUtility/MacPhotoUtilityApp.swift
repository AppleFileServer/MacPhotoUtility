import SwiftUI
import MacPhotoKit

/// MacPhoto Utility: a placeholder window until Phase 3 builds the real one.
@main
struct MacPhotoUtilityApp: App {
    var body: some Scene {
        Window("MacPhoto Utility", id: "main") {
            VStack(spacing: 8) {
                Text("MacPhoto Utility").font(.title2)
                Text("\(AppVersion.string): the window comes in Phase 3.")
                    .foregroundStyle(.secondary)
            }
            .padding(40)
        }
    }
}
