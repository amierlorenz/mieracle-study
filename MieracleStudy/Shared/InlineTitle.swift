import SwiftUI

extension View {
    /// Forms nested in the split view lose their large title on iPhone; an
    /// inline title stays visible.
    func inlineTitleOnPhone() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
