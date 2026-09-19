//
//  InteractiveQuizView.swift
//  StudyOS
//

import SwiftUI

public struct InteractiveQuizView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var inputText: String
    @State private var isProcessing: Bool = false
    @State private var questions: [QuizQuestionItem] = []
    @State private var currentIndex: Int = 0
    @State private var selectedOptionIndex: Int? = nil
    @State private var hasSubmittedAnswer: Bool = false
    @State private var correctAnswersCount: Int = 0
    @State private var isQuizFinished: Bool = false
    @State private var errorMessage: String?

    public init(initialText: String = "") {
        _inputText = State(initialValue: initialText)
    }

    private var currentQuestion: QuizQuestionItem? {
        guard !questions.isEmpty && currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    public var body: some View {
        Group {
            if questions.isEmpty {
                inputQuizView
            } else if isQuizFinished {
                quizScoreReportView
            } else {
                activeQuizQuestionView
            }
        }
        .navigationTitle("Practice Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .onAppear {
            if !inputText.isEmpty && questions.isEmpty {
                generateQuiz()
            }
        }
    }

    private var inputQuizView: some View {
        Form {
            Section("Study Material Source") {
                TextField("Paste notes or reading passage to generate quiz questions...", text: $inputText, axis: .vertical)
                    .lineLimit(6...12)

                Button {
                    Haptics.tap()
                    generateQuiz()
                } label: {
                    if isProcessing {
                        ProgressView()
                    } else {
                        Label("Generate 5-Question Quiz", systemImage: "questionmark.circle")
                            .font(.body.weight(.medium))
                    }
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isProcessing)
            }

            if let errorMessage {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Couldn't generate a quiz", systemImage: "exclamationmark.triangle")
                            .font(.subheadline.weight(.semibold))
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button("Try Again") {
                            Haptics.tap()
                            generateQuiz()
                        }
                        .font(.subheadline.weight(.medium))
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .dismissibleKeyboard()
    }

    private var activeQuizQuestionView: some View {
        List {
            Section {
                Text("Question \(currentIndex + 1) of \(questions.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ProgressView(value: Double(currentIndex + 1), total: Double(questions.count))
            }

            if let question = currentQuestion {
                Section("Prompt") {
                    Text(question.prompt)
                        .font(.headline)
                        .padding(.vertical, 4)
                }

                Section("Options") {
                    ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                        Button {
                            guard !hasSubmittedAnswer else { return }
                            Haptics.selection()
                            selectedOptionIndex = index
                        } label: {
                            HStack {
                                Image(systemName: optionIcon(for: index, question: question))
                                    .foregroundStyle(optionColor(for: index, question: question))
                                Text(option)
                                    .font(.body)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .disabled(hasSubmittedAnswer)
                    }
                }

                if hasSubmittedAnswer {
                    Section("Explanation") {
                        Text(question.explanation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Section {
                        Button {
                            nextQuestion()
                        } label: {
                            Text(currentIndex + 1 < questions.count ? "Next Question" : "View Final Score")
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if selectedOptionIndex != nil {
                    Section {
                        Button {
                            submitAnswer()
                        } label: {
                            Text("Submit Answer")
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var quizScoreReportView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: correctAnswersCount >= (questions.count / 2) ? "trophy.fill" : "book.fill")
                .font(.system(.largeTitle))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Quiz Completed")
                    .font(.title2.weight(.bold))

                Text("You scored \(correctAnswersCount) out of \(questions.count) correct (\(Int((Double(correctAnswersCount) / Double(questions.count)) * 100))%).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Finish Review")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private func generateQuiz() {
        isProcessing = true
        errorMessage = nil
        Task {
            do {
                let q = try await OnDeviceStudyAIService.shared.generateQuiz(text: inputText, questionCount: 5)
                await MainActor.run {
                    self.questions = q
                    self.currentIndex = 0
                    self.selectedOptionIndex = nil
                    self.hasSubmittedAnswer = false
                    self.correctAnswersCount = 0
                    self.isQuizFinished = false
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Your text is saved below. Longer passages with clear facts produce better questions."
                    self.isProcessing = false
                }
            }
        }
    }

    private func submitAnswer() {
        guard let selected = selectedOptionIndex, let question = currentQuestion else { return }
        hasSubmittedAnswer = true
        if selected == question.correctOptionIndex {
            correctAnswersCount += 1
            Haptics.success()
        } else {
            Haptics.warning()
        }
    }

    private func nextQuestion() {
        if currentIndex + 1 < questions.count {
            currentIndex += 1
            selectedOptionIndex = nil
            hasSubmittedAnswer = false
        } else {
            isQuizFinished = true
        }
    }

    private func optionIcon(for index: Int, question: QuizQuestionItem) -> String {
        if !hasSubmittedAnswer {
            return selectedOptionIndex == index ? "largecircle.fill.circle" : "circle"
        }
        if index == question.correctOptionIndex {
            return "checkmark.circle.fill"
        }
        if index == selectedOptionIndex {
            return "xmark.circle.fill"
        }
        return "circle"
    }

    private func optionColor(for index: Int, question: QuizQuestionItem) -> Color {
        if !hasSubmittedAnswer {
            return selectedOptionIndex == index ? Color.accentColor : .secondary
        }
        if index == question.correctOptionIndex {
            return .green
        }
        if index == selectedOptionIndex {
            return .red
        }
        return .secondary
    }
}
