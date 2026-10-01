import SwiftUI

extension View {
    /// Gives sheets a usable size on macOS, where they otherwise size to their content.
    func sheetFrame() -> some View {
        #if os(macOS)
        frame(minWidth: 520, idealWidth: 620, minHeight: 480, idealHeight: 640)
        #else
        self
        #endif
    }
}
