//
//  StudyAIServiceProtocol.swift
//  StudyOS
//

import Foundation

public protocol StudyAIServiceProtocol: Sendable {
    var processingLocation: AIProcessingLocation { get }

    func summarize(text: String) async throws -> StudySummaryResult
    func explainConcept(concept: String, context: String?) async throws -> ConceptExplanationResult
    func generateFlashcards(text: String, targetCount: Int) async throws -> [FlashcardItem]
    func generateQuiz(text: String, questionCount: Int) async throws -> [QuizQuestionItem]
    func identifyKeyConcepts(text: String) async throws -> [ConceptItem]
    func generateStudyPlan(materialText: String, totalDays: Int, availableHoursPerDay: Double) async throws -> [StudyPlanMilestone]
}
