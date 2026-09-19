//
//  OnDeviceStudyAIService.swift
//  StudyOS
//

import Foundation
import NaturalLanguage

public final class OnDeviceStudyAIService: StudyAIServiceProtocol, Sendable {
    public static let shared = OnDeviceStudyAIService()

    public var processingLocation: AIProcessingLocation {
        .onDevice
    }

    public init() {}

    public func summarize(text: String) async throws -> StudySummaryResult {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else {
            return StudySummaryResult(
                coreSummary: "No material content provided to summarize.",
                keyTakeaways: [],
                estimatedReadingTimeMinutes: 0
            )
        }

        let sentences = extractSentences(from: cleanText)
        let wordCount = cleanText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let readingTime = max(1, Int(ceil(Double(wordCount) / 200.0)))

        // Score sentences by word importance and position
        let scored = scoreSentences(sentences)
        let topCount = min(3, max(1, sentences.count / 3))
        let topSentences = Array(scored.prefix(topCount))
        let coreSummary = topSentences.map(\.text).joined(separator: " ")

        // Extract key takeaways (bullet points)
        var takeaways: [String] = []
        for item in scored.prefix(5) {
            let trimmed = item.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !takeaways.contains(trimmed) {
                takeaways.append(trimmed)
            }
        }

        return StudySummaryResult(
            coreSummary: coreSummary.isEmpty ? cleanText : coreSummary,
            keyTakeaways: takeaways,
            estimatedReadingTimeMinutes: readingTime,
            processingLocation: .onDevice
        )
    }

    public func explainConcept(concept: String, context: String?) async throws -> ConceptExplanationResult {
        let trimmedConcept = concept.trimmingCharacters(in: .whitespacesAndNewlines)

        var contextHints = ""
        if let context = context, !context.isEmpty {
            let sentences = extractSentences(from: context).filter {
                $0.localizedCaseInsensitiveContains(trimmedConcept)
            }
            if let firstMatch = sentences.first {
                contextHints = firstMatch
            }
        }

        let simpleExplanation = contextHints.isEmpty
            ? "\(trimmedConcept) is a foundational topic in this subject. It represents the core mechanism by which related components interact and produce predictable results."
            : "\(contextHints) In plain terms, \(trimmedConcept.lowercased()) acts as a fundamental building block."

        let analogy = "Think of \(trimmedConcept.lowercased()) like the foundation of a house: everything built on top depends on its rules and structural integrity."

        let steps = [
            "Identify the core definition and where \(trimmedConcept.lowercased()) occurs in problems.",
            "Observe the inputs, conditions, or governing rules that apply to it.",
            "Test your understanding by walking through a simple example or edge case."
        ]

        let misconception = "A frequent pitfall is memorizing \(trimmedConcept.lowercased()) in isolation without connecting it to the surrounding principles."

        return ConceptExplanationResult(
            concept: trimmedConcept,
            simpleExplanation: simpleExplanation,
            analogy: analogy,
            stepByStepBreakdown: steps,
            commonMisconception: misconception,
            processingLocation: .onDevice
        )
    }

    public func generateFlashcards(text: String, targetCount: Int) async throws -> [FlashcardItem] {
        let sentences = extractSentences(from: text)
        guard !sentences.isEmpty else { return [] }

        var cards: [FlashcardItem] = []
        let definitionIndicators = [" is ", " are ", " defined as ", " refers to ", " means ", " represents ", ": "]

        for sentence in sentences {
            guard cards.count < targetCount else { break }

            for indicator in definitionIndicators {
                if let range = sentence.range(of: indicator, options: .caseInsensitive) {
                    let front = String(sentence[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let back = String(sentence[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)

                    let wordCountFront = front.split(separator: " ").count
                    if wordCountFront >= 1 && wordCountFront <= 6 && back.split(separator: " ").count >= 3 {
                        let card = FlashcardItem(front: front, back: back)
                        if !cards.contains(where: { $0.front.caseInsensitiveCompare(card.front) == .orderedSame }) {
                            cards.append(card)
                            break
                        }
                    }
                }
            }
        }

        // Fallback: create conceptual question cards from prominent sentences
        if cards.count < targetCount {
            for sentence in sentences where cards.count < targetCount {
                let words = sentence.split(separator: " ")
                if words.count > 5 && words.count < 25 {
                    let prompt = "Key Concept: What principle is described by \"\(sentence)\"?"
                    let answer = sentence
                    let card = FlashcardItem(front: prompt, back: answer)
                    if !cards.contains(where: { $0.front == card.front }) {
                        cards.append(card)
                    }
                }
            }
        }

        return cards
    }

    public func generateQuiz(text: String, questionCount: Int) async throws -> [QuizQuestionItem] {
        let cards = try await generateFlashcards(text: text, targetCount: max(questionCount * 2, 4))
        guard !cards.isEmpty else { return [] }

        var quiz: [QuizQuestionItem] = []

        for card in cards.prefix(questionCount) {
            let correctAnswer = card.back

            // Distractors come from other cards' answers; pad with clearly generic
            // options only when the deck is too small, never duplicating the answer.
            var distractors = cards.filter { $0.id != card.id }.map(\.back)
            let genericOptions = [
                "None of the above",
                "A related but incorrect principle",
                "An unrelated concept"
            ]
            for candidate in genericOptions where distractors.count < 3 && candidate != correctAnswer {
                distractors.append(candidate)
            }

            var options = Array(distractors.shuffled().prefix(3))
            let correctIndex = Int.random(in: 0...min(3, options.count))
            options.insert(correctAnswer, at: min(correctIndex, options.count))

            let prompt = "What is the definition or primary function of: \(card.front)?"
            let explanation = "Correct answer: \(correctAnswer). Derived directly from your study notes."

            let question = QuizQuestionItem(
                prompt: prompt,
                options: options,
                correctOptionIndex: correctIndex,
                explanation: explanation
            )
            quiz.append(question)
        }

        return quiz
    }

    public func identifyKeyConcepts(text: String) async throws -> [ConceptItem] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text

        var wordFrequencies: [String: Int] = [:]
        let stopWords = Set(["the", "and", "a", "an", "in", "on", "of", "to", "for", "with", "is", "are", "was", "were", "that", "this", "by", "as", "at", "from", "it", "be", "or", "which"])

        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let word = String(text[range]).lowercased()
            if word.count > 3 && !stopWords.contains(word) && !word.allSatisfy(\.isNumber) {
                wordFrequencies[word, default: 0] += 1
            }
            return true
        }

        let sortedWords = wordFrequencies.sorted { $0.value > $1.value }
        let sentences = extractSentences(from: text)

        var concepts: [ConceptItem] = []
        for (word, _) in sortedWords.prefix(8) {
            let matchingSentence = sentences.first { $0.localizedCaseInsensitiveContains(word) } ?? "Key topic occurring across the material."
            let concept = ConceptItem(
                name: word.capitalized,
                summary: "Appears frequently in this unit as an important subject mechanism.",
                contextSentence: matchingSentence
            )
            concepts.append(concept)
        }

        return concepts
    }

    public func generateStudyPlan(materialText: String, totalDays: Int, availableHoursPerDay: Double) async throws -> [StudyPlanMilestone] {
        let days = max(1, totalDays)
        let concepts = try await identifyKeyConcepts(text: materialText)
        var milestones: [StudyPlanMilestone] = []

        let dailyMinutes = Int(availableHoursPerDay * 60)
        let topicsPerDay = max(1, Int(ceil(Double(concepts.count) / Double(days))))

        for day in 1...days {
            let startIndex = min((day - 1) * topicsPerDay, concepts.count)
            let endIndex = min(day * topicsPerDay, concepts.count)
            let dayTopics = startIndex < endIndex ? Array(concepts[startIndex..<endIndex].map(\.name)) : ["Review & Practice Quiz"]

            let title: String
            if day == 1 {
                title = "Initial Review & Core Concepts"
            } else if day == days {
                title = "Final Synthesis & Practice Testing"
            } else {
                title = "Deep Dive: \(dayTopics.first ?? "Key Principles")"
            }

            let milestone = StudyPlanMilestone(
                dayOffset: day,
                title: title,
                recommendedDurationMinutes: min(dailyMinutes, 60),
                focusTopics: dayTopics
            )
            milestones.append(milestone)
        }

        return milestones
    }

    // MARK: - Sentence Extraction & Scoring

    private func extractSentences(from text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        var sentences: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty {
                sentences.append(sentence)
            }
            return true
        }

        if sentences.isEmpty {
            return text.components(separatedBy: .newlines).filter { !$0.isEmpty }
        }
        return sentences
    }

    private struct ScoredSentence {
        let text: String
        let score: Double
    }

    private func scoreSentences(_ sentences: [String]) -> [ScoredSentence] {
        var scored: [ScoredSentence] = []
        for (index, sentence) in sentences.enumerated() {
            var score = 1.0
            // Boost beginning and early sentences
            if index < 3 { score += 2.0 }
            // Boost length between 10 and 30 words
            let wordCount = sentence.split(separator: " ").count
            if wordCount >= 10 && wordCount <= 30 {
                score += 1.5
            }
            // Boost key phrases
            let keywords = ["important", "key", "result", "conclude", "principle", "therefore", "fundamental", "theorem"]
            for keyword in keywords {
                if sentence.localizedCaseInsensitiveContains(keyword) {
                    score += 1.0
                }
            }
            scored.append(ScoredSentence(text: sentence, score: score))
        }

        return scored.sorted { $0.score > $1.score }
    }
}
