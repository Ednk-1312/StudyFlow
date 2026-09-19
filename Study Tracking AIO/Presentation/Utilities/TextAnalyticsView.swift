//
//  TextAnalyticsView.swift
//  StudyOS
//

import SwiftUI

public struct TextAnalyticsView: View {
    @State private var textInput: String = ""

    public init() {}

    private var analysis: StudentCalculators.TextAnalysisResult {
        StudentCalculators.analyzeText(textInput)
    }

    public var body: some View {
        Form {
            Section("Essay / Text Input") {
                TextField("Paste essay, assignment, or speech draft here...", text: $textInput, axis: .vertical)
                    .lineLimit(6...14)
            }

            Section("Counts") {
                HStack {
                    Text("Words")
                    Spacer()
                    Text("\(analysis.wordCount)")
                        .font(.body.weight(.semibold))
                }

                HStack {
                    Text("Characters (with spaces)")
                    Spacer()
                    Text("\(analysis.characterCount)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Characters (no spaces)")
                    Spacer()
                    Text("\(analysis.characterCountNoSpaces)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Sentences")
                    Spacer()
                    Text("\(analysis.sentenceCount)")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Estimated Duration") {
                HStack {
                    Label("Reading Time (~220 wpm)", systemImage: "book")
                    Spacer()
                    Text(formattedSeconds(analysis.readingTimeSeconds))
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Speaking Time (~130 wpm)", systemImage: "mic")
                    Spacer()
                    Text(formattedSeconds(analysis.speakingTimeSeconds))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .dismissibleKeyboard()
        .navigationTitle("Word Counter")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formattedSeconds(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) sec"
        } else {
            let m = seconds / 60
            let s = seconds % 60
            return s > 0 ? "\(m)m \(s)s" : "\(m) min"
        }
    }
}
