import WebKit
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Keeps the rendered page in place and opens clicked links in the default browser.
struct ExternalLinkDecider: WebPage.NavigationDeciding {
    func decidePolicy(for action: WebPage.NavigationAction, preferences: inout WebPage.NavigationPreferences) async -> WKNavigationActionPolicy {
        guard let url = action.request.url, url.scheme != BundleAssetSchemeHandler.scheme else { return .allow }
        if action.navigationType == .linkActivated, ["http", "https", "mailto"].contains(url.scheme) {
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #else
            await UIApplication.shared.open(url)
            #endif
        }
        return .cancel
    }
}
