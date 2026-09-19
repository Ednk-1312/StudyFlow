//
//  MaterialSummarizerView.swift
//  StudyOS
//

import SwiftUI

public struct MaterialSummarizerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var inputText: String
    @State private var isProcessing: Bool = false
    @State private var summaryResult: StudySummaryResult?
    @State private var errorMessage: String?

    public init(initialText: String = "") {
        _inputText = State(initialValue: initialText)
    }

    public var body: some View {
        List {
            Section("Study Material Content") {
                TextField("Paste text, notes, or reading passage to summarize...", text: $inputText, axis: .vertical)
                    .lineLimit(5...10)

                Button {
                    Haptics.tap()
                    generateSummary()
                } label: {
                    if isProcessing {
                        ProgressView()
                    } else {
                        Label("Generate Summary", systemImage: "text.quote")
                            .font(.body.weight(.medium))
                    }
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isProcessing)
            }

            if let errorMessage {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Couldn't summarize this text", systemImage: "exclamationmark.triangle")
                            .font(.subheadline.weight(.semibold))
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button("Try Again") {
                            Haptics.tap()
                            generateSummary()
                        }
                        .font(.subheadline.weight(.medium))
                    }
                    .padding(.vertical, 2)
                }
            }

            if let result = summaryResult {
                Section("Core Summary") {
                    Text(result.coreSummary)
                        .font(.body)
                        .textSelection(.enabled)
                }

                if !result.keyTakeaways.isEmpty {
                    Section("Key Takeaways") {
                        ForEach(result.keyTakeaways, id: \.self) { takeaway in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.caption2)
                                .padding(.top, 6)
                                .foregroundStyle(.tertiary)
                                Text(takeaway)
                                    .font(.subheadline)
                            }
                        }
                    }
                }

                Section {
                    HStack {
                        Label("Estimated Reading Time", systemImage: "book")
                        Spacer()
                        Text("\(result.estimatedReadingTimeMinutes) min")
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Generated on this device with Apple's NaturalLanguage framework. Treat the result as a starting point and verify it against your course materials.")
                        .font(.caption2)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .dismissibleKeyboard()
        .navigationTitle("Material Summarizer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .onAppear {
            if !inputText.isEmpty && summaryResult == nil {
                generateSummary()
            }
        }
    }

    private func generateSummary() {
        isProcessing = true
        errorMessage = nil
        Task {
            do {
                let result = try await OnDeviceStudyAIService.shared.summarize(text: inputText)
                await MainActor.run {
                    self.summaryResult = result
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Your text is saved below and can be copied. Try again, or check that it contains enough readable content."
                    self.isProcessing = false
                }
            }
        }
    }
}
