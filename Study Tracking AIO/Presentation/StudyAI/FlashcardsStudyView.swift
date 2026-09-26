//
//  FlashcardsStudyView.swift
//  StudyOS
//

import SwiftUI

public struct FlashcardsStudyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var inputText: String
    @State private var isProcessing: Bool = false
    @State private var flashcards: [FlashcardItem] = []
    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    @State private var errorMessage: String?
    @State private var isDeckFinished: Bool = false
    /// Queue of card indices to visit during a focused review pass.
    /// Empty during a normal first pass through the deck.
    @State private var reviewQueue: [Int] = []

    public init(initialText: String = "") {
        _inputText = State(initialValue: initialText)
    }

    private var currentCard: FlashcardItem? {
        guard !flashcards.isEmpty && currentIndex < flashcards.count else { return nil }
        return flashcards[currentIndex]
    }

    private var masteredCount: Int {
        flashcards.filter(\.isMastered).count
    }

    public var body: some View {
        Group {
            if flashcards.isEmpty {
                inputDeckView
            } else if isDeckFinished {
                deckCompleteView
            } else {
                activeDeckView
            }
        }
        .navigationTitle("Flashcards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .onAppear {
            if !inputText.isEmpty && flashcards.isEmpty {
                generateCards()
            }
        }
    }

    // Step 1: Input or Generate
    private var inputDeckView: some View {
        Form {
            Section("Study Material Source") {
                TextField("Paste notes, vocabulary, or text to convert into flashcards...", text: $inputText, axis: .vertical)
                    .lineLimit(6...12)

                Button {
                    Haptics.tap()
                    generateCards()
                } label: {
                    if isProcessing {
                        ProgressView()
                    } else {
                        Label("Generate Flashcard Deck", systemImage: "rectangle.on.rectangle.angled")
                            .font(.body.weight(.medium))
                    }
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isProcessing)
            }

            if let errorMessage {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Couldn't generate flashcards", systemImage: "exclamationmark.triangle")
                            .font(.subheadline.weight(.semibold))
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button("Try Again") {
                            Haptics.tap()
                            generateCards()
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

    // Step 3: End-of-deck summary instead of an abrupt dismissal.
    private var deckCompleteView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.largeTitle)
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Deck Complete")
                    .font(.title2.weight(.bold))
                Text("You mastered \(masteredCount) of \(flashcards.count) cards.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Haptics.tap()
                    reviewUnmastered()
                } label: {
                    Label("Review Unmastered Cards", systemImage: "arrow.counterclockwise")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(masteredCount == flashcards.count)

                Button("Done") {
                    dismiss()
                }
                .font(.body.weight(.medium))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // Step 2: Interactive Study Mode
    private var activeDeckView: some View {
        VStack(spacing: 20) {
            // Header Progress
            HStack {
                Text("Card \(currentIndex + 1) of \(flashcards.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(masteredCount) Mastered")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            ProgressView(value: Double(currentIndex + 1), total: Double(flashcards.count))
                .padding(.horizontal, 24)

            Spacer()

            // Card Container
            if let card = currentCard {
                Button {
                    Haptics.tap()
                    withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
                        isFlipped.toggle()
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.platformSecondaryGroupedBackground)
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.platformSeparator, lineWidth: 0.5)
                            )

                        VStack(spacing: 16) {
                Text(isFlipped ? "Answer" : "Question")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                            Spacer()

                            Text(isFlipped ? card.back : card.front)
                                .font(.title3.weight(.medium))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color.primary)
                                .padding(.horizontal, 24)

                            Spacer()

                            Text("Tap to flip")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(24)
                    }
                    .frame(height: 320)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFlipped ? "Answer: \(card.back)" : "Question: \(card.front)")
                .accessibilityHint("Double tap to flip card")
            }

            Spacer()

            // Bottom Mastery Buttons
            HStack(spacing: 20) {
                Button {
                    Haptics.tap()
                    markCard(mastered: false)
                } label: {
                    Label("Need Practice", systemImage: "arrow.counterclockwise")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                .controlSize(.large)

                Button {
                    Haptics.success()
                    markCard(mastered: true)
                } label: {
                    Label("Mastered", systemImage: "checkmark")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.large)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private func generateCards() {
        isProcessing = true
        errorMessage = nil
        Task {
            do {
                let cards = try await OnDeviceStudyAIService.shared.generateFlashcards(text: inputText, targetCount: 8)
                await MainActor.run {
                    self.flashcards = cards
                    self.currentIndex = 0
                    self.isFlipped = false
                    self.isDeckFinished = false
                    self.reviewQueue = []
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Your text is saved below. Add more distinct facts or terms — short passages may not produce a useful deck."
                    self.isProcessing = false
                }
            }
        }
    }

    private func markCard(mastered: Bool) {
        if currentIndex < flashcards.count {
            flashcards[currentIndex].isMastered = mastered
        }
        isFlipped = false

        if !reviewQueue.isEmpty {
            reviewQueue.removeFirst()
            if let next = reviewQueue.first {
                currentIndex = next
            } else {
                isDeckFinished = true
            }
            return
        }

        if currentIndex + 1 < flashcards.count {
            currentIndex += 1
        } else {
            // Reached end of deck
            isDeckFinished = true
        }
    }

    private func reviewUnmastered() {
        let remaining = flashcards.enumerated().filter { !$0.element.isMastered }.map(\.offset)
        guard let first = remaining.first else { return }
        reviewQueue = remaining
        currentIndex = first
        isFlipped = false
        isDeckFinished = false
    }
}
