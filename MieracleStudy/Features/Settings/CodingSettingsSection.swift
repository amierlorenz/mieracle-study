import MieracleKit
import SwiftUI

struct CodingSettingsSection: View {
    @AppStorage(SettingsKey.pythonPath) private var pythonPath = PythonRunner.detectedPythonPath ?? ""

    var body: some View {
        Section {
            TextField("Python interpreter", text: $pythonPath)
                .monospaced()
            LabeledContent("Status", value: isInstalled ? "Found" : "Not found")
            if let detected = PythonRunner.detectedPythonPath, detected != pythonPath {
                Button("Use \(detected)") { pythonPath = detected }
            }
        } header: {
            Text("Coding")
        } footer: {
            Text("Coding problems run your solution with this python3 in a temporary folder, stopping after 5 seconds.")
        }
    }

    private var isInstalled: Bool {
        FileManager.default.isExecutableFile(atPath: pythonPath)
    }
}
