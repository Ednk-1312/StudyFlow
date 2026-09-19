//
//  StudyAIHubView.swift
//  StudyOS
//

import SwiftUI
import SwiftData

public struct StudyAIHubView: View {
    @Query(sort: \Material.createdAt, order: .reverse) private var materials: [Material]

    @State private var selectedTool: AIToolType? = nil

    public enum AIToolType: String, Identifiable {
        case summarizer
        case explainer
        case flashcards
        case quiz

        public var id: String { rawValue }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            hubContent
        }
    }

    private var hubContent: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "iphone.gen3")
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Runs on this device")
                            .font(.subheadline.weight(.medium))
                        Text("These tools analyze text with Apple's on-device NaturalLanguage framework. Nothing you paste or save here leaves your device.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .combine)
            }

            Section("Study Tools") {
                ForEach(toolRows) { row in
                    Button {
                        selectedTool = row.tool
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: row.systemImage)
                                .foregroundStyle(.tint)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.title)
                                    .font(.body)
                                    .foregroundStyle(Color.primary)
                                Text(row.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section {
                if materials.isEmpty {
                    Text("No materials yet. Notes and documents you add in Materials can be opened with these tools.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(materials.prefix(8)) { material in
                        NavigationLink(destination: MaterialDetailView(material: material)) {
                            HStack {
                                Image(systemName: material.fileType.systemImage)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(material.title)
                                        .font(.body)
                                    Text(material.subject)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("Your Materials")
            } footer: {
                Text("Open a material to summarize it or generate flashcards from its text.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Study AI")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedTool) { tool in
            NavigationStack {
                switch tool {
                case .summarizer:
                    MaterialSummarizerView()
                case .explainer:
                    ConceptExplainerView()
                case .flashcards:
                    FlashcardsStudyView()
                case .quiz:
                    InteractiveQuizView()
                }
            }
        }
    }

    private struct ToolRowData: Identifiable {
        let tool: AIToolType
        let title: String
        let subtitle: String
        let systemImage: String
        var id: String { tool.rawValue }
    }

    private var toolRows: [ToolRowData] {
        [
            ToolRowData(tool: .summarizer, title: "Summarize Text", subtitle: "Key sentences and takeaways from pasted material", systemImage: "text.quote"),
            ToolRowData(tool: .explainer, title: "Explain a Concept", subtitle: "Plain-language breakdown of a term or idea", systemImage: "lightbulb"),
            ToolRowData(tool: .flashcards, title: "Make Flashcards", subtitle: "Turn definitions in your notes into a deck", systemImage: "rectangle.on.rectangle.angled"),
            ToolRowData(tool: .quiz, title: "Practice Quiz", subtitle: "Multiple-choice questions from your notes", systemImage: "questionmark.circle")
        ]
    }
}
