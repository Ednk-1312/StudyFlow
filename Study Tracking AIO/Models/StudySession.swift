//
//  StudySession.swift
//  StudyOS
//

import Foundation
import SwiftData

public enum StudySessionStatus: String, Codable, CaseIterable {
    case planned = "Planned"
    case active = "Active"
    case paused = "Paused"
    case completed = "Completed"
    case abandoned = "Abandoned"
}

@Model
public final class StudySession {
    @Attribute(.unique) public var id: UUID
    public var assignmentID: UUID?
    public var subject: String
    public var plannedStart: Date
    public var plannedDuration: TimeInterval // seconds
    public var actualDuration: TimeInterval  // seconds active
    public var statusRaw: String
    public var notes: String
    public var breaksDuration: TimeInterval  // seconds on break
    public var interruptionsCount: Int
    public var completedAt: Date?
    public var createdAt: Date

    public var status: StudySessionStatus {
        get { StudySessionStatus(rawValue: statusRaw) ?? .planned }
        set { statusRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        assignmentID: UUID? = nil,
        subject: String,
        plannedStart: Date = Date(),
        plannedDuration: TimeInterval = 25 * 60,
        actualDuration: TimeInterval = 0,
        status: StudySessionStatus = .planned,
        notes: String = "",
        breaksDuration: TimeInterval = 0,
        interruptionsCount: Int = 0,
        completedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.assignmentID = assignmentID
        self.subject = subject
        self.plannedStart = plannedStart
        self.plannedDuration = plannedDuration
        self.actualDuration = actualDuration
        self.statusRaw = status.rawValue
        self.notes = notes
        self.breaksDuration = breaksDuration
        self.interruptionsCount = interruptionsCount
        self.completedAt = completedAt
        self.createdAt = createdAt
    }
}
