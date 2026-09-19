//
//  NotificationManagerProtocol.swift
//  StudyOS
//

import Foundation
import UserNotifications

@MainActor
public protocol NotificationManaging: Sendable {
    func checkAuthorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func scheduleAssignmentReminders(for assignment: Assignment) async throws
    func cancelAssignmentReminders(for assignmentID: UUID) async
    func scheduleExamReminders(for exam: ExamEvent) async throws
    func cancelExamReminders(for examID: UUID) async
    func scheduleStudySessionNotification(title: String, body: String, scheduledDate: Date, sessionID: UUID) async throws
    func cancelStudySessionNotification(sessionID: UUID) async
    func cancelAllNotifications() async
    func getPendingNotificationCount() async -> Int
}
