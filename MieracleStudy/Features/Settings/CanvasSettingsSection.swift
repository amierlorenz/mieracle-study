import MieracleKit
import OSLog
import SwiftUI

struct CanvasSettingsSection: View {
    @AppStorage(SettingsKey.canvasBaseURL) private var baseURL = ""
    @State private var tokenInput = ""
    @State private var hasToken = false
    @State private var status: String?

    var body: some View {
        Section {
            TextField("Canvas URL", text: $baseURL, prompt: Text(verbatim: "https://school.instructure.com"))
                .autocorrectionDisabled()
            SecureField(hasToken ? "Token saved — paste to replace" : "Access token", text: $tokenInput)
            HStack {
                Button("Save Token", action: saveToken)
                    .disabled(tokenInput.trimmingCharacters(in: .whitespaces).isEmpty)
                if hasToken {
                    Button("Remove Token", role: .destructive, action: removeToken)
                }
                Spacer()
                Button("Test Connection") { Task { await testConnection() } }
                    .disabled(!hasToken || baseURL.isEmpty)
            }
            if let status {
                Text(status)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Canvas")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text("To get a token:")
                Text("1. In Canvas, open Account → Settings.")
                Text("2. Under Approved Integrations, choose New Access Token.")
                Text("3. Set the expiration date 90 days out (the maximum).")
                Text("4. Copy the token and paste it above, then Save Token.")
                Text("It's stored only in your Keychain and synced through iCloud Keychain.")
            }
        }
        .onAppear(perform: loadTokenState)
    }

    private func loadTokenState() {
        hasToken = ((try? KeychainStore.canvasToken.read()) ?? nil) != nil
    }

    private func saveToken() {
        do {
            try KeychainStore.canvasToken.save(tokenInput.trimmingCharacters(in: .whitespacesAndNewlines))
            tokenInput = ""
            hasToken = true
            status = "Token saved."
        } catch {
            Logger.app.error("Saving Canvas token failed: \(error)")
            status = "Couldn't save the token."
        }
    }

    private func removeToken() {
        try? KeychainStore.canvasToken.delete()
        hasToken = false
        status = "Token removed."
    }

    private func testConnection() async {
        guard let client = CanvasService().client() else {
            status = "Enter an https Canvas URL and save a token first."
            return
        }
        do {
            let courses = try await client.activeCourses()
            status = "Connected. \(courses.count) active courses."
        } catch CanvasClient.ClientError.unauthorized {
            status = "Canvas rejected the token."
        } catch {
            status = "Couldn't reach Canvas: \(error.localizedDescription)"
        }
    }
}
