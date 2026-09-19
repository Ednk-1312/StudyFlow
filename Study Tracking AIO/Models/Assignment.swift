//
//  Assignment.swift
//  StudyOS
//

import Foundation
import SwiftData

public enum AssignmentPriority: String, Codable, CaseIterable, Comparable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"

    public var sortOrder: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .urgent: return 3
        }
    }

    public static func < (lhs: AssignmentPriority, rhs: AssignmentPriority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

public enum AssignmentStatus: String, Codable, CaseIterable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case completed = "Completed"
    case overdue = "Overdue"

    public var isCompleted: Bool {
        self == .completed
    }
}

public enum AssignmentSource: String, Codable, CaseIterable {
    case manual = "Manual"
    case googleClassroom = "Google Classroom"
    case cameraScan = "Camera Scan"
    case documentImport = "Document Import"
    case aiExtracted = "AI Extracted"
}

@Model
public final class Assignment {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var subject: String
    public var courseName: String
    public var dueDate: Date
    public var estimatedMinutes: Int
    public var priorityRaw: String
    public var statusRaw: String
    public var notes: String
    public var sourceRaw: String
    public var externalIdentifier: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var completedAt: Date?
    public var lastSyncedAt: Date?
    public var materialIDs: [UUID]

    public var priority: AssignmentPriority {
        get { AssignmentPriority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }

    public var status: AssignmentStatus {
        get {
            if statusRaw == AssignmentStatus.completed.rawValue {
                return .completed
            }
            if dueDate < Date() && statusRaw != AssignmentStatus.completed.rawValue {
                return .overdue
            }
            return AssignmentStatus(rawValue: statusRaw) ?? .notStarted
        }
        set {
            statusRaw = newValue.rawValue
            if newValue == .completed {
                completedAt = Date()
            } else {
                completedAt = nil
            }
            updatedAt = Date()
        }
    }

    public var source: AssignmentSource {
        get { AssignmentSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        title: String,
        subject: String,
        courseName: String = "",
        dueDate: Date,
        estimatedMinutes: Int = 45,
        priority: AssignmentPriority = .medium,
        status: AssignmentStatus = .notStarted,
        notes: String = "",
        source: AssignmentSource = .manual,
        externalIdentifier: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil,
        lastSyncedAt: Date? = nil,
        materialIDs: [UUID] = []
    ) {
        self.id = id
        self.title = title
        self.subject = subject
        self.courseName = courseName.isEmpty ? subject : courseName
        self.dueDate = dueDate
        self.estimatedMinutes = max(5, estimatedMinutes)
        self.priorityRaw = priority.rawValue
        self.statusRaw = status.rawValue
        self.notes = notes
        self.sourceRaw = source.rawValue
        self.externalIdentifier = externalIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.lastSyncedAt = lastSyncedAt
        self.materialIDs = materialIDs
    }
}
