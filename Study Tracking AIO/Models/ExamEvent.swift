//
//  ExamEvent.swift
//  StudyOS
//

import Foundation
import SwiftData

public enum ExamType: String, Codable, CaseIterable {
    case quiz = "Quiz"
    case test = "Chapter Test"
    case midterm = "Midterm"
    case finalExam = "Final Exam"
    case presentation = "Presentation"
    case project = "Project Submission"
    case standardized = "Standardized Test"

    public var systemImage: String {
        switch self {
        case .quiz: return "checklist"
        case .test: return "doc.text.magnifyingglass"
        case .midterm: return "graduationcap"
        case .finalExam: return "graduationcap.fill"
        case .presentation: return "person.crop.rectangle"
        case .project: return "folder.badge.gearshape"
        case .standardized: return "star.circle"
        }
    }
}

@Model
public final class ExamEvent {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var subject: String
    public var date: Date
    public var typeRaw: String
    public var notes: String
    public var preparationDays: Int
    public var priorityRaw: String
    public var createdAt: Date
    public var updatedAt: Date

    public var type: ExamType {
        get { ExamType(rawValue: typeRaw) ?? .test }
        set { typeRaw = newValue.rawValue }
    }

    public var priority: AssignmentPriority {
        get { AssignmentPriority(rawValue: priorityRaw) ?? .high }
        set { priorityRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        title: String,
        subject: String,
        date: Date,
        type: ExamType = .test,
        notes: String = "",
        preparationDays: Int = 5,
        priority: AssignmentPriority = .high,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.subject = subject
        self.date = date
        self.typeRaw = type.rawValue
        self.notes = notes
        self.preparationDays = max(1, preparationDays)
        self.priorityRaw = priority.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// The date when the study preparation window begins
    public var preparationStartDate: Date {
        Calendar.current.date(byAdding: .day, value: -preparationDays, to: date) ?? date
    }

    /// Checks whether the user is currently inside the preparation window
    public var isInsidePreparationWindow: Bool {
        let now = Date()
        return now >= preparationStartDate && now <= date
    }
}
