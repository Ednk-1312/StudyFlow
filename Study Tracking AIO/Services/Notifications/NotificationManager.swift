//
//  NotificationManager.swift
//  StudyOS
//

import Foundation
import UserNotifications

public final class NotificationManager: NotificationManaging, @unchecked Sendable {
    public static let shared = NotificationManager()

    private let notificationCenter: UNUserNotificationCenter

    public enum Category: String {
        case assignmentDueSoon = "ASSIGNMENT_DUE_SOON"
        case assignmentOverdue = "ASSIGNMENT_OVERDUE"
        case studySession = "STUDY_SESSION"
        case examApproaching = "EXAM_APPROACHING"
        case plannedTask = "PLANNED_TASK"
        case syncIssue = "SYNC_ISSUE"
    }

    public init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
        registerCategories()
    }

    private func registerCategories() {
        let completeAction = UNNotificationAction(
            identifier: "MARK_COMPLETE",
            title: "Mark Complete",
            options: [.authenticationRequired]
        )
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_1H",
            title: "Remind in 1 Hour",
            options: []
        )

        let dueSoonCategory = UNNotificationCategory(
            identifier: Category.assignmentDueSoon.rawValue,
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        let overdueCategory = UNNotificationCategory(
            identifier: Category.assignmentOverdue.rawValue,
            actions: [completeAction],
            intentIdentifiers: [],
            options: []
        )

        let studySessionCategory = UNNotificationCategory(
            identifier: Category.studySession.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let examCategory = UNNotificationCategory(
            identifier: Category.examApproaching.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([
            dueSoonCategory,
            overdueCategory,
            studySessionCategory,
            examCategory
        ])
    }

    public func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    public func requestAuthorization() async throws -> Bool {
        return try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
    }

    public func scheduleAssignmentReminders(for assignment: Assignment) async throws {
        // First cancel any existing reminders for this assignment to prevent duplicates
        await cancelAssignmentReminders(for: assignment.id)

        guard assignment.status != .completed else { return }

        let status = await checkAuthorizationStatus()
        guard status == .authorized || status == .provisional else { return }

        let now = Date()

        // 1. 24 hours before due date
        let reminder24h = assignment.dueDate.addingTimeInterval(-24 * 3600)
        if reminder24h > now {
            let content = UNMutableNotificationContent()
            content.title = "\(assignment.courseName): Due Tomorrow"
            content.body = "\(assignment.title) is due tomorrow at \(DateFormatter.localizedString(from: assignment.dueDate, dateStyle: .none, timeStyle: .short))."
            content.sound = .default
            content.categoryIdentifier = Category.assignmentDueSoon.rawValue
            content.userInfo = ["assignmentID": assignment.id.uuidString]

            let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder24h)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let request = UNNotificationRequest(identifier: "assignment-due-24h-\(assignment.id.uuidString)", content: content, trigger: trigger)
            try await notificationCenter.add(request)
        }

        // 2. 3 hours before due date
        let reminder3h = assignment.dueDate.addingTimeInterval(-3 * 3600)
        if reminder3h > now {
            let content = UNMutableNotificationContent()
            content.title = "\(assignment.courseName): Due in 3 Hours"
            content.body = "\(assignment.title) is due at \(DateFormatter.localizedString(from: assignment.dueDate, dateStyle: .none, timeStyle: .short))."
            content.sound = .default
            content.categoryIdentifier = Category.assignmentDueSoon.rawValue
            content.userInfo = ["assignmentID": assignment.id.uuidString]

            let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder3h)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let request = UNNotificationRequest(identifier: "assignment-due-3h-\(assignment.id.uuidString)", content: content, trigger: trigger)
            try await notificationCenter.add(request)
        }

        // 3. Overdue notification at due date + 15 min
        let overdueDate = assignment.dueDate.addingTimeInterval(15 * 60)
        if overdueDate > now {
            let content = UNMutableNotificationContent()
            content.title = "Overdue: \(assignment.courseName)"
            content.body = "\(assignment.title) was due. Tap to complete or update progress."
            content.sound = .default
            content.categoryIdentifier = Category.assignmentOverdue.rawValue
            content.userInfo = ["assignmentID": assignment.id.uuidString]

            let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: overdueDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let request = UNNotificationRequest(identifier: "assignment-overdue-\(assignment.id.uuidString)", content: content, trigger: trigger)
            try await notificationCenter.add(request)
        }
    }

    public func cancelAssignmentReminders(for assignmentID: UUID) async {
        let idString = assignmentID.uuidString
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let identifiersToRemove = pendingRequests
            .map(\.identifier)
            .filter { $0.contains(idString) }

        if !identifiersToRemove.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiersToRemove)
        }
    }

    public func scheduleExamReminders(for exam: ExamEvent) async throws {
        await cancelExamReminders(for: exam.id)

        let status = await checkAuthorizationStatus()
        guard status == .authorized || status == .provisional else { return }

        let now = Date()

        // 1. Preparation window start reminder
        let prepStart = exam.preparationStartDate
        if prepStart > now {
            let content = UNMutableNotificationContent()
            content.title = "Exam Prep Window: \(exam.subject)"
            content.body = "\(exam.title) is in \(exam.preparationDays) days. Time to begin your review sessions."
            content.sound = .default
            content.categoryIdentifier = Category.examApproaching.rawValue
            content.userInfo = ["examID": exam.id.uuidString]

            let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: prepStart)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let request = UNNotificationRequest(identifier: "exam-prep-\(exam.id.uuidString)", content: content, trigger: trigger)
            try await notificationCenter.add(request)
        }

        // 2. Day before exam reminder (evening at 18:00)
        if let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: exam.date) {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: dayBefore)
            components.hour = 18
            components.minute = 0
            if let date = Calendar.current.date(from: components), date > now {
                let content = UNMutableNotificationContent()
                content.title = "Tomorrow: \(exam.subject) \(exam.type.rawValue)"
                content.body = "\(exam.title) is tomorrow. Make sure materials are reviewed and get a good night's rest."
                content.sound = .default
                content.categoryIdentifier = Category.examApproaching.rawValue
                content.userInfo = ["examID": exam.id.uuidString]

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: "exam-daybefore-\(exam.id.uuidString)", content: content, trigger: trigger)
                try await notificationCenter.add(request)
            }
        }
    }

    public func cancelExamReminders(for examID: UUID) async {
        let idString = examID.uuidString
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let identifiersToRemove = pendingRequests
            .map(\.identifier)
            .filter { $0.contains(idString) }

        if !identifiersToRemove.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiersToRemove)
        }
    }

    public func scheduleStudySessionNotification(title: String, body: String, scheduledDate: Date, sessionID: UUID) async throws {
        let status = await checkAuthorizationStatus()
        guard status == .authorized || status == .provisional else { return }

        guard scheduledDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = Category.studySession.rawValue
        content.userInfo = ["sessionID": sessionID.uuidString]

        let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: scheduledDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "session-\(sessionID.uuidString)", content: content, trigger: trigger)
        try await notificationCenter.add(request)
    }

    public func cancelStudySessionNotification(sessionID: UUID) async {
        let identifier = "session-\(sessionID.uuidString)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    public func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }

    public func getPendingNotificationCount() async -> Int {
        let pending = await notificationCenter.pendingNotificationRequests()
        return pending.count
    }
}
