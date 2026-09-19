//
//  AssignmentStore.swift
//  StudyOS
//

import Foundation
import SwiftData
import UserNotifications
import WidgetKit

/// Single home for assignment mutations (complete, delete, save) so every
/// screen gets identical save/reminder/Spotlight/undo behavior.
@MainActor
public final class AssignmentStore {
    public static let shared = AssignmentStore()

    public init() {}

    /// Persists a change, surfacing failures instead of discarding them.
    private static func persist(_ context: ModelContext) {
        do {
            try context.saveOrThrow()
        } catch {
            AppState.shared.dataErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Notification permission (contextual)

    /// Requests notification authorization once, when the user schedules their
    /// first real reminder. Safe to call repeatedly.
    public func ensureReminderPermissionIfNeeded() async {
        let status = await NotificationManager.shared.checkAuthorizationStatus()
        guard status == .notDetermined else { return }
        _ = try? await NotificationManager.shared.requestAuthorization()
    }

    // MARK: - Completion

    /// Toggles completion, returns a closure that undoes the change.
    public func toggleCompletion(of assignment: Assignment, in context: ModelContext) -> () -> Void {
        let previousStatus = assignment.status
        let completed = previousStatus != .completed

        assignment.status = completed ? .completed : .notStarted
        Self.persist(context)
        WidgetSnapshotWriter.reload(context: context)

        let assignmentID = assignment.id
        let snapshot = assignment
        Task {
            if completed {
                await NotificationManager.shared.cancelAssignmentReminders(for: assignmentID)
            } else {
                try? await NotificationManager.shared.scheduleAssignmentReminders(for: snapshot)
            }
            SpotlightIndexer.shared.indexAssignment(snapshot)
        }

        return {
            assignment.status = previousStatus
            Self.persist(context)
            WidgetSnapshotWriter.reload(context: context)
            Task {
                if previousStatus == .completed {
                    await NotificationManager.shared.cancelAssignmentReminders(for: assignmentID)
                } else {
                    try? await NotificationManager.shared.scheduleAssignmentReminders(for: assignment)
                }
            }
        }
    }

    // MARK: - Deletion with undo

    /// Deletes an assignment while keeping enough state to restore it.
    /// Returns a closure that undoes the deletion.
    public func delete(_ assignment: Assignment, in context: ModelContext) -> () -> Void {
        // Plain snapshot (not inserted into any context) so it can be
        // re-inserted verbatim if the user taps Undo.
        let snapshot = Assignment(
            id: assignment.id,
            title: assignment.title,
            subject: assignment.subject,
            courseName: assignment.courseName,
            dueDate: assignment.dueDate,
            estimatedMinutes: assignment.estimatedMinutes,
            priority: assignment.priority,
            status: assignment.statusRaw == AssignmentStatus.completed.rawValue ? .completed : .notStarted,
            notes: assignment.notes,
            source: assignment.source,
            externalIdentifier: assignment.externalIdentifier,
            createdAt: assignment.createdAt,
            updatedAt: assignment.updatedAt,
            completedAt: assignment.completedAt,
            lastSyncedAt: assignment.lastSyncedAt,
            materialIDs: assignment.materialIDs
        )
        let assignmentID = assignment.id

        Task {
            await NotificationManager.shared.cancelAssignmentReminders(for: assignmentID)
            SpotlightIndexer.shared.deindexAssignment(id: assignmentID)
        }

        context.delete(assignment)
        Self.persist(context)
        WidgetSnapshotWriter.reload(context: context)

        return {
            context.insert(snapshot)
            Self.persist(context)
            WidgetSnapshotWriter.reload(context: context)
            Task {
                try? await NotificationManager.shared.scheduleAssignmentReminders(for: snapshot)
                SpotlightIndexer.shared.indexAssignment(snapshot)
            }
        }
    }

    // MARK: - New assignment helpers

    public func reminderIDs(for assignment: Assignment) -> [String] {
        [
            "assignment-due-24h-\(assignment.id.uuidString)",
            "assignment-due-3h-\(assignment.id.uuidString)",
            "assignment-overdue-\(assignment.id.uuidString)"
        ]
    }

    /// Saves a newly created assignment: persists, schedules reminders after
    /// ensuring contextual permission, and indexes for Spotlight.
    public func saveNew(_ assignment: Assignment, in context: ModelContext) {
        context.insert(assignment)
        Self.persist(context)
        WidgetSnapshotWriter.reload(context: context)

        let snapshot = assignment
        Task {
            await ensureReminderPermissionIfNeeded()
            try? await NotificationManager.shared.scheduleAssignmentReminders(for: snapshot)
            SpotlightIndexer.shared.indexAssignment(snapshot)
        }
    }
}
