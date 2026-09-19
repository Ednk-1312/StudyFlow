//
//  StudyOSShortcuts.swift
//  StudyOS
//

import AppIntents

public struct StudyOSShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartStudySessionIntent(),
            phrases: [
                "Start study session in \(.applicationName)",
                "Start studying in \(.applicationName)"
            ],
            shortTitle: "Start Study Session",
            systemImageName: "play.fill"
        )

        AppShortcut(
            intent: ShowTodayAssignmentsIntent(),
            phrases: [
                "Show today's assignments in \(.applicationName)",
                "Show my homework in \(.applicationName)"
            ],
            shortTitle: "Today's Assignments",
            systemImageName: "checklist"
        )
    }
}
