//
//  WidgetSnapshotWriter.swift
//  StudyOS
//
//  The app is the single writer of widget data. Every meaningful local change
//  (assignments saved/completed/deleted/edited, exams added, sessions started
//  or finished) refreshes a compact snapshot in the shared app group and asks
//  WidgetKit to reload. Widgets then render real local state without opening
//  the SwiftData store themselves.
//
//  The JSON shape must stay identical to WidgetKitExtension/WidgetSnapshot.swift.
//

import Foundation
import SwiftData
import WidgetKit

@MainActor
public enum WidgetSnapshotWriter {

    private static let maxAssignments = 8

    /// Rebuilds the snapshot from the current store and reloads widget
    /// timelines. Cheap: a bounded fetch plus one small file write.
    public static func reload(context: ModelContext) {
        let snapshot = buildSnapshot(context: context)
        write(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Snapshot construction

    private static func buildSnapshot(context: ModelContext) -> WidgetSnapshot {
        var snapshot = WidgetSnapshot(generatedAt: Date(), assignments: [], nextExam: nil, activeSession: currentSessionCard())

        // Open, non-completed assignments, soonest due first.
        var assignmentDescriptor = FetchDescriptor<Assignment>(
            sortBy: [SortDescriptor(\.dueDate, order: .forward)]
        )
        assignmentDescriptor.fetchLimit = maxAssignments * 2
        if let all = try? context.fetch(assignmentDescriptor) {
            snapshot.assignments = all
                .filter { $0.status != .completed }
                .prefix(maxAssignments)
                .map { assignment in
                    AssignmentCard(
                        id: assignment.id,
                        title: assignment.title,
                        courseName: assignment.courseName,
                        dueDate: assignment.dueDate,
                        estimatedMinutes: assignment.estimatedMinutes,
                        isOverdue: assignment.status == .overdue
                    )
                }
        }

        // Next upcoming exam, if any.
        let now = Date()
        var examDescriptor = FetchDescriptor<ExamEvent>(
            predicate: #Predicate { $0.date >= now },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        examDescriptor.fetchLimit = 1
        if let exam = try? context.fetch(examDescriptor).first {
            snapshot.nextExam = ExamCard(
                title: exam.title,
                subject: exam.subject,
                date: exam.date,
                typeName: exam.type.rawValue
            )
        }

        return snapshot
    }

    /// The session state lives in AppState; widgets only need the coarse card.
    private static func currentSessionCard() -> SessionCard? {
        let appState = AppState.shared
        guard appState.isStudySessionActive else { return nil }
        return SessionCard(
            assignmentTitle: appState.activeStudySessionAssignment?.title,
            plannedMinutes: appState.activeSessionPlannedMinutes
        )
    }

    // MARK: - Persistence

    private static func write(_ snapshot: WidgetSnapshot) {
        guard let url = WidgetSnapshot.storageURL else { return }
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: url, options: .atomic)
        } catch {
            // Widget data is a derived cache; a failed write must never
            // interrupt the user's action. Widgets fall back to their
            // empty state and will refresh on the next successful write.
        }
    }
}
