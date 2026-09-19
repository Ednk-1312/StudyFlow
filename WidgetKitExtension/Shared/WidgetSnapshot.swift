//
//  WidgetSnapshot.swift
//  StudyOSWidgets
//
//  The app serializes a compact snapshot of its local SwiftData state into the
//  shared app group so widgets can render real data without opening the
//  container. This file mirrors App/WidgetSnapshotWriter.swift in the app
//  target — keep the JSON keys identical in both places.
//

import Foundation

public struct AssignmentCard: Codable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var courseName: String
    public var dueDate: Date
    public var estimatedMinutes: Int
    public var isOverdue: Bool

    public init(id: UUID, title: String, courseName: String, dueDate: Date, estimatedMinutes: Int, isOverdue: Bool) {
        self.id = id
        self.title = title
        self.courseName = courseName
        self.dueDate = dueDate
        self.estimatedMinutes = estimatedMinutes
        self.isOverdue = isOverdue
    }
}

public struct ExamCard: Codable, Hashable, Sendable {
    public var title: String
    public var subject: String
    public var date: Date
    public var typeName: String

    public init(title: String, subject: String, date: Date, typeName: String) {
        self.title = title
        self.subject = subject
        self.date = date
        self.typeName = typeName
    }
}

/// A session currently running in the app. Deliberately coarse: the widget
/// shows that a session is in progress and for how long it was planned; the
/// live countdown lives in the app. Pauses in the app would make any widget
/// countdown drift, so none is shown here.
public struct SessionCard: Codable, Hashable, Sendable {
    public var assignmentTitle: String?
    public var plannedMinutes: Int

    public init(assignmentTitle: String?, plannedMinutes: Int) {
        self.assignmentTitle = assignmentTitle
        self.plannedMinutes = plannedMinutes
    }
}

public struct WidgetSnapshot: Codable, Sendable {
    public var generatedAt: Date
    public var assignments: [AssignmentCard]
    public var nextExam: ExamCard?
    public var activeSession: SessionCard?

    public init(generatedAt: Date, assignments: [AssignmentCard], nextExam: ExamCard?, activeSession: SessionCard?) {
        self.generatedAt = generatedAt
        self.assignments = assignments
        self.nextExam = nextExam
        self.activeSession = activeSession
    }

    public static let appGroupID = "group.com.Study-Tracking-AIO"
    static let fileName = "widget-snapshot.json"

    public static var storageURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(fileName)
    }

    /// Reads the latest snapshot written by the app. Returns nil when the app
    /// has never written one (fresh install, widget relaunched before app).
    public static func load() -> WidgetSnapshot? {
        guard let url = storageURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

}
