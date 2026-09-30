enum Platform {
    static var supportsCodeExecution: Bool {
        #if os(macOS)
        true
        #else
        false
        #endif
    }
}
