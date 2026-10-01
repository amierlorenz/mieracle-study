import MieracleKit
import OSLog
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(VariantGenerationService.self) private var variantGeneration
    @AppStorage(SettingsKey.aiModel) private var aiModel = FoundationModelsProvider.ModelChoice.onDevice.rawValue
    @State private var pending: PendingImport?
    @State private var errorMessage: String?
    @State private var resultMessage: String?
    @State private var isChoosingFile = false
    @State private var isShowingGenerator = false
    @State private var export: JSONFileDocument?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button("Copy AI Generator Prompt…", systemImage: "sparkles") { isShowingGenerator = true }
                } header: {
                    Text("1. Generate")
                } footer: {
                    Text("Paste the prompt into Claude with your slides or notes, then import the JSON it returns.")
                }
                Section {
                    Button("Choose JSON File…", systemImage: "doc") { isChoosingFile = true }
                    Button("Paste JSON from Clipboard", systemImage: "doc.on.clipboard", action: importFromClipboard)
                } header: {
                    Text("2. Import")
                } footer: {
                    #if os(macOS)
                    Text("You can also drop a .json file here.")
                    #endif
                }
                if let pending {
                    ImportPreviewSection(pending: pending, onApply: apply, onCancel: cancel)
                }
                if let errorMessage {
                    Section("Couldn't Read File") {
                        Label(errorMessage, systemImage: "xmark.octagon.fill")
                            .foregroundStyle(.red)
                    }
                }
                if let resultMessage {
                    Section {
                        Label(resultMessage, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                Section("Backup") {
                    Button("Export Everything…", systemImage: "square.and.arrow.up", action: prepareExport)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Import")
            .inlineTitleOnPhone()
            .fileImporter(isPresented: $isChoosingFile, allowedContentTypes: [.json], onCompletion: importFile)
            .fileExporter(isPresented: isExporting, document: export, contentType: .json, defaultFilename: exportFilename) { _ in
                export = nil
            }
            .dropDestination(for: URL.self) { urls, _ in
                guard let url = urls.first else { return false }
                load(from: url)
                return true
            }
            .sheet(isPresented: $isShowingGenerator) {
                GeneratorPromptSheet()
            }
        }
    }

    private var isExporting: Binding<Bool> {
        Binding { export != nil } set: { if !$0 { export = nil } }
    }

    private var exportFilename: String {
        "MieracleStudy \(Date.now.formatted(.iso8601.year().month().day())).json"
    }

    private func importFile(_ result: Result<URL, any Error>) {
        switch result {
        case .success(let url): load(from: url)
        case .failure(let error): show(error: error.localizedDescription)
        }
    }

    private func load(from url: URL) {
        let isScoped = url.startAccessingSecurityScopedResource()
        defer { if isScoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let document = try ImportDocument.decode(from: Data(contentsOf: url))
            stage(document, source: url.lastPathComponent)
        } catch let error as ImportDecodingError {
            show(error: error.message)
        } catch {
            show(error: error.localizedDescription)
        }
    }

    private func importFromClipboard() {
        do {
            stage(try ImportDocument.decode(fromPasted: Clipboard.string ?? ""), source: "Clipboard")
        } catch {
            show(error: error.message)
        }
    }

    private func stage(_ document: ImportDocument, source: String) {
        do {
            let plan = try Importer(context: modelContext).plan(document)
            pending = PendingImport(source: source, document: document, plan: plan)
            errorMessage = nil
            resultMessage = nil
        } catch {
            show(error: error.localizedDescription)
        }
    }

    private func apply() {
        guard let pending else { return }
        do {
            let plan = try Importer(context: modelContext).apply(pending.document)
            resultMessage = "Imported \(plan.concepts.new) new and \(plan.concepts.updated) updated concepts, \(plan.prompts.new + plan.prompts.updated) prompts."
            self.pending = nil
            variantGeneration.start(context: modelContext, provider: FoundationModelsProvider(storedChoice: aiModel))
        } catch {
            show(error: error.localizedDescription)
        }
    }

    private func cancel() {
        pending = nil
    }

    private func prepareExport() {
        do {
            export = JSONFileDocument(data: try Exporter(context: modelContext).document().encoded())
        } catch {
            Logger.app.error("Export failed: \(error)")
            show(error: error.localizedDescription)
        }
    }

    private func show(error message: String) {
        errorMessage = message
        resultMessage = nil
        pending = nil
    }
}
