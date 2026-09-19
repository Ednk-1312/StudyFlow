//
//  StudyOSIntents.swift
//  StudyOS
//

import AppIntents
import SwiftData

public struct StartStudySessionIntent: AppIntent {
    public static var title: LocalizedStringResource = "Start Study Session"
    public static var description = IntentDescription("Starts a focused study session in StudyOS.")
    public static var openAppWhenRun: Bool = true

    @Parameter(title: "Duration Minutes", default: 25)
    public var durationMinutes: Int

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        AppState.shared.startStudySession(durationMinutes: durationMinutes)
        return .result()
    }
}

public struct ShowTodayAssignmentsIntent: AppIntent {
    public static var title: LocalizedStringResource = "Show Today's Assignments"
    public static var description = IntentDescription("Navigates to today's school assignments in StudyOS.")
    public static var openAppWhenRun: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        AppState.shared.selectedTab = .home
        return .result()
    }
}

public struct QuickAddAssignmentIntent: AppIntent {
    public static var title: LocalizedStringResource = "Add Assignment"
    public static var description = IntentDescription("Quickly opens the new assignment screen in StudyOS.")
    public static var openAppWhenRun: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        AppState.shared.isQuickAddPresented = true
        return .result()
    }
}
