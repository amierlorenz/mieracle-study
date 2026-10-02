import MieracleKit
import SwiftUI

/// Copies an item's Canvas link, briefly showing a checkmark.
struct CopyCanvasLinkButton: View {
    let item: CanvasItem

    @AppStorage(SettingsKey.canvasBaseURL) private var canvasBaseURL = ""
    @State private var didCopy = false

    var body: some View {
        if let url = item.webURL(canvasBaseURL: URL(string: canvasBaseURL)) {
            Button(didCopy ? "Copied" : "Copy Canvas Link", systemImage: didCopy ? "checkmark" : "link") {
                copy(url)
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .contentTransition(.symbolEffect(.replace))
            .help("Copy Canvas link")
        }
    }

    private func copy(_ url: URL) {
        Clipboard.copy(url.absoluteString)
        withAnimation(.spring(duration: 0.3)) { didCopy = true }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.spring(duration: 0.3)) { didCopy = false }
        }
    }
}
