//
//  StudyAIModels.swift
//  StudyOS
//

import Foundation

public enum AIProcessingLocation: String, Codable, Sendable {
    case onDevice = "100% On-Device (Apple NaturalLanguage)"
    case appleManaged = "Apple Foundation Models"
    case thirdParty = "Third-Party Cloud"

    public var badgeTitle: String {
        switch self {
        case .onDevice: return "On-Device"
        case .appleManaged: return "Apple Intelligence"
        case .thirdParty: return "Cloud Service"
        }
    }

    public var isPrivateOnDevice: Bool {
        self == .onDevice || self == .appleManaged
    }
}

public struct FlashcardItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let front: String // Question or term
    public let back: String  // Answer or definition
    public var isMastered: Bool

    public init(id: UUID = UUID(), front: String, back: String, isMastered: Bool = false) {
        self.id = id
        self.front = front
        self.back = back
        self.isMastered = isMastered
    }
}

public struct QuizQuestionItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let prompt: String
    public let options: [String]
    public let correctOptionIndex: Int
    public let explanation: String

    public init(id: UUID = UUID(), prompt: String, options: [String], correctOptionIndex: Int, explanation: String) {
        self.id = id
        self.prompt = prompt
        self.options = options
        self.correctOptionIndex = correctOptionIndex
        self.explanation = explanation
    }
}

public struct ConceptItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let summary: String
    public let contextSentence: String

    public init(id: UUID = UUID(), name: String, summary: String, contextSentence: String) {
        self.id = id
        self.name = name
        self.summary = summary
        self.contextSentence = contextSentence
    }
}

public struct StudyPlanMilestone: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let dayOffset: Int
    public let title: String
    public let recommendedDurationMinutes: Int
    public let focusTopics: [String]

    public init(id: UUID = UUID(), dayOffset: Int, title: String, recommendedDurationMinutes: Int, focusTopics: [String]) {
        self.id = id
        self.dayOffset = dayOffset
        self.title = title
        self.recommendedDurationMinutes = recommendedDurationMinutes
        self.focusTopics = focusTopics
    }
}

public struct StudySummaryResult: Equatable, Sendable {
    public let coreSummary: String
    public let keyTakeaways: [String]
    public let estimatedReadingTimeMinutes: Int
    public let processingLocation: AIProcessingLocation

    public init(coreSummary: String, keyTakeaways: [String], estimatedReadingTimeMinutes: Int, processingLocation: AIProcessingLocation = .onDevice) {
        self.coreSummary = coreSummary
        self.keyTakeaways = keyTakeaways
        self.estimatedReadingTimeMinutes = estimatedReadingTimeMinutes
        self.processingLocation = processingLocation
    }
}

public struct ConceptExplanationResult: Equatable, Sendable {
    public let concept: String
    public let simpleExplanation: String
    public let analogy: String
    public let stepByStepBreakdown: [String]
    public let commonMisconception: String?
    public let processingLocation: AIProcessingLocation

    public init(concept: String, simpleExplanation: String, analogy: String, stepByStepBreakdown: [String], commonMisconception: String? = nil, processingLocation: AIProcessingLocation = .onDevice) {
        self.concept = concept
        self.simpleExplanation = simpleExplanation
        self.analogy = analogy
        self.stepByStepBreakdown = stepByStepBreakdown
        self.commonMisconception = commonMisconception
        self.processingLocation = processingLocation
    }
}
