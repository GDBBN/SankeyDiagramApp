import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var project = SankeyProject.example
    @State private var exportDocument = DataDocument(data: Data())
    @State private var exportType: UTType = .json
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var isCreatingNewProject = false
    @State private var shareImage: UIImage?
    @State private var errorMessage: String?

    var body: some View {
        appContent
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
            importProject(result)
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: exportType,
            defaultFilename: safeFilename
        ) { result in
            if case .failure(let error) = result {
                errorMessage = error.localizedDescription
            }
        }
        .sheet(isPresented: Binding(
            get: { shareImage != nil },
            set: { if !$0 { shareImage = nil } }
        )) {
            if let shareImage {
                ShareSheet(items: [shareImage])
            }
        }
        .confirmationDialog(
            "Neues Diagramm erstellen?",
            isPresented: $isCreatingNewProject,
            titleVisibility: .visible
        ) {
            Button("Neues Diagramm", role: .destructive) {
                project = .empty
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Nicht gespeicherte Änderungen gehen verloren.")
        }
        .alert("Aktion fehlgeschlagen", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var appContent: some View {
        if horizontalSizeClass == .compact {
            TabView {
                NavigationStack {
                    ProjectEditorView(project: $project)
                        .toolbar { actionToolbar }
                }
                .tabItem {
                    Label("Bearbeiten", systemImage: "slider.horizontal.3")
                }

                NavigationStack {
                    diagramDetail
                        .toolbar { actionToolbar }
                }
                .tabItem {
                    Label("Vorschau", systemImage: "chart.bar.xaxis")
                }
            }
        } else {
            NavigationSplitView {
                ProjectEditorView(project: $project)
                    .navigationSplitViewColumnWidth(min: 340, ideal: 420, max: 520)
            } detail: {
                diagramDetail
                    .toolbar { actionToolbar }
            }
        }
    }

    private var diagramDetail: some View {
        SankeyDiagramView(project: project)
            .padding()
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Vorschau")
    }

    @ToolbarContentBuilder
    private var actionToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("Neu", systemImage: "doc.badge.plus") {
                isCreatingNewProject = true
            }
            Button("Projekt laden", systemImage: "folder") {
                isImporting = true
            }
            Menu("Exportieren", systemImage: "square.and.arrow.up") {
                Button("Projekt speichern", systemImage: "doc") {
                    exportProject()
                }
                Button("PNG speichern", systemImage: "photo") {
                    exportPNG()
                }
                Button("PNG teilen", systemImage: "square.and.arrow.up") {
                    shareImage = renderImage()
                }
            }
        }
    }

    private var safeFilename: String {
        let cleaned = project.title
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
        return cleaned.isEmpty ? "Mein-Finanzfluss" : cleaned
    }

    private func exportProject() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            exportDocument = DataDocument(data: try encoder.encode(project))
            exportType = .json
            isExporting = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func exportPNG() {
        guard let data = renderImage()?.pngData() else {
            errorMessage = "Das Diagramm konnte nicht als PNG gerendert werden."
            return
        }
        exportDocument = DataDocument(data: data)
        exportType = .png
        isExporting = true
    }

    @MainActor
    private func renderImage() -> UIImage? {
        let view = SankeyDiagramView(project: project)
            .frame(width: 1_800, height: 1_100)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        return renderer.uiImage
    }

    private func importProject(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            let data = try Data(contentsOf: url)
            project = try JSONDecoder().decode(SankeyProject.self, from: data)
        } catch {
            errorMessage = "Das Projekt konnte nicht geladen werden: \(error.localizedDescription)"
        }
    }
}
