//
//  Reminder.swift
//  StudyOS
//

import Foundation
import SwiftData

public enum ReminderType: String, Codable, CaseIterable {
    case dueSoon = "Due Soon"
    case overdue = "Overdue"
    case studySession = "Study Session"
    case examApproaching = "Exam Approaching"
    case plannedTask = "Planned Task"
    case syncIssue = "Sync Issue"
}

@Model
public final class Reminder {
    @Attribute(.unique) public var id: UUID
    public var assignmentID: UUID?
    public var examID: UUID?
    public var title: String
    public var scheduledDate: Date
    public var notificationIdentifier: String
    public var enabled: Bool
    public var reminderTypeRaw: String
    public var createdAt: Date

    public var reminderType: ReminderType {
        get { ReminderType(rawValue: reminderTypeRaw) ?? .dueSoon }
        set { reminderTypeRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        assignmentID: UUID? = nil,
        examID: UUID? = nil,
        title: String,
        scheduledDate: Date,
        notificationIdentifier: String = UUID().uuidString,
        enabled: Bool = true,
        reminderType: ReminderType = .dueSoon,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.assignmentID = assignmentID
        self.examID = examID
        self.title = title
        self.scheduledDate = scheduledDate
        self.notificationIdentifier = notificationIdentifier
        self.enabled = enabled
        self.reminderTypeRaw = reminderType.rawValue
        self.createdAt = createdAt
    }
}
