//
//  MaterialDetailView.swift
//  StudyOS
//

import SwiftUI
import SwiftData
import PDFKit

public struct MaterialDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    public let material: Material

    @State private var isDeleteConfirmationPresented: Bool = false
    @State private var activeAITool: ActiveAITool? = nil

    public enum ActiveAITool: Identifiable {
        case summary
        case flashcards
        case quiz
        case explainer

        public var id: Int {
            switch self {
            case .summary: return 1
            case .flashcards: return 2
            case .quiz: return 3
            case .explainer: return 4
            }
        }
    }

    public init(material: Material) {
        self.material = material
    }

    private var contentText: String {
        material.extractedTextReference ?? ""
    }

    public var body: some View {
        List {
            // Header Info
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        SubjectTag(subject: material.subject)
                        Spacer()
                        Label(material.fileType.rawValue, systemImage: material.fileType.systemImage)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Text(material.title)
                        .font(.title2.weight(.bold))

                    if !material.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(material.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(uiColor: .tertiarySystemFill))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // Document / Image / Note Viewer
            if let fileRef = material.localFileReference,
               let data = try? LocalStorageManager.shared.readFile(relativeFileName: fileRef) {
                if material.fileType == .pdf {
                    Section("PDF Document Preview") {
                        NativePDFView(data: data)
                            .frame(height: 380)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                } else if let uiImage = UIImage(data: data) {
                    Section("Attached Image") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }

            // Extracted Text / Notes Section
            if !contentText.isEmpty {
                Section("Content & Extracted Text") {
                    Text(contentText)
                        .font(.body)
                        .textSelection(.enabled)
                }

                // AI Study Tools Section
                Section("On-Device AI Study Tools") {
                    Button {
                        activeAITool = .summary
                    } label: {
                        Label("Summarize Material", systemImage: "text.quote")
                    }

                    Button {
                        activeAITool = .flashcards
                    } label: {
                        Label("Generate Flashcards", systemImage: "rectangle.on.rectangle.angled")
                    }

                    Button {
                        activeAITool = .quiz
                    } label: {
                        Label("Generate Practice Quiz", systemImage: "questionmark.circle")
                    }

                    Button {
                        activeAITool = .explainer
                    } label: {
                        Label("Explain Key Concepts", systemImage: "lightbulb")
                    }
                }
            }

            // Destructive Delete Action
            Section {
                Button(role: .destructive) {
                    isDeleteConfirmationPresented = true
                } label: {
                    Label("Delete Material", systemImage: "trash")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(material.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeAITool) { tool in
            NavigationStack {
                switch tool {
                case .summary:
                    MaterialSummarizerView(initialText: contentText)
                case .flashcards:
                    FlashcardsStudyView(initialText: contentText)
                case .quiz:
                    InteractiveQuizView(initialText: contentText)
                case .explainer:
                    ConceptExplainerView(initialContext: contentText)
                }
            }
        }
        .confirmationDialog("Delete Material?", isPresented: $isDeleteConfirmationPresented, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let ref = material.localFileReference {
                    try? LocalStorageManager.shared.deleteFile(relativeFileName: ref)
                }
                SpotlightIndexer.shared.deindexMaterial(id: material.id)
                modelContext.delete(material)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \"\(material.title)\" and any local files attached to it.")
        }
    }
}

public struct NativePDFView: UIViewRepresentable {
    public let data: Data

    public init(data: Data) {
        self.data = data
    }

    public func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.document = PDFDocument(data: data)
        return pdfView
    }

    public func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document == nil {
            uiView.document = PDFDocument(data: data)
        }
    }
}
