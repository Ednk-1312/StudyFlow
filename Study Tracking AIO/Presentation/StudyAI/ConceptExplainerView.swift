//
//  ConceptExplainerView.swift
//  StudyOS
//

import SwiftUI

public struct ConceptExplainerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var conceptQuery: String = ""
    @State private var contextText: String
    @State private var isProcessing: Bool = false
    @State private var explanationResult: ConceptExplanationResult?
    @State private var errorMessage: String?

    public init(initialConcept: String = "", initialContext: String = "") {
        _conceptQuery = State(initialValue: initialConcept)
        _contextText = State(initialValue: initialContext)
    }

    public var body: some View {
        List {
            Section("Concept to Explain") {
                TextField("E.g. Mitosis, Derivatives, Supply & Demand...", text: $conceptQuery)

                Button {
                    Haptics.tap()
                    explain()
                } label: {
                    if isProcessing {
                        ProgressView()
                    } else {
                        Label("Explain Concept", systemImage: "lightbulb")
                            .font(.body.weight(.medium))
                    }
                }
                .disabled(conceptQuery.trimmingCharacters(in: .whitespaces).isEmpty || isProcessing)
            }

            if let errorMessage {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Couldn't explain \"\(conceptQuery)\"", systemImage: "exclamationmark.triangle")
                            .font(.subheadline.weight(.semibold))
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button("Try Again") {
                            Haptics.tap()
                            explain()
                        }
                        .font(.subheadline.weight(.medium))
                    }
                    .padding(.vertical, 2)
                }
            }

            if let result = explanationResult {
                Section("Plain Language Explanation") {
                    Text(result.simpleExplanation)
                        .font(.body)
                }

                Section("Real-World Analogy") {
                    Text(result.analogy)
                        .font(.body)
                        .italic()
                }

                Section("Step-by-Step Breakdown") {
                    ForEach(Array(result.stepByStepBreakdown.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.secondary)
                            Text(step)
                                .font(.subheadline)
                        }
                    }
                }

                if let misconception = result.commonMisconception {
                    Section("Common Pitfall to Avoid") {
                        Label(misconception, systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .dismissibleKeyboard()
        .navigationTitle("Concept Explainer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func explain() {
        isProcessing = true
        errorMessage = nil
        Task {
            do {
                let result = try await OnDeviceStudyAIService.shared.explainConcept(
                    concept: conceptQuery,
                    context: contextText.isEmpty ? nil : contextText
                )
                await MainActor.run {
                    self.explanationResult = result
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Try a shorter concept name, or add more context text so there's more to work from."
                    self.isProcessing = false
                }
            }
        }
    }
}
