import MieracleKit
import SwiftUI

struct CodingSettingsSection: View {
    @AppStorage(SettingsKey.pythonPath) private var pythonPath = PythonRunner.detectedPythonPath ?? ""

    var body: some View {
        Section {
            TextField("Python interpreter", text: $pythonPath)
                .monospaced()
            LabeledContent("Python", value: isInstalled ? "Found" : "Not found")
            LabeledContent("Swift", value: SwiftRunner.isAvailable ? "Found (xcrun swiftc)" : "Needs Xcode or Command Line Tools")
            if let detected = PythonRunner.detectedPythonPath, detected != pythonPath {
                Button("Use \(detected)") { pythonPath = detected }
            }
        } header: {
            Text("Coding")
        } footer: {
            Text("Solutions run in a temporary folder and stop after 5 seconds per run. Swift solutions are compiled first, which takes a few seconds.")
        }
    }

    private var isInstalled: Bool {
        FileManager.default.isExecutableFile(atPath: pythonPath)
    }
}
