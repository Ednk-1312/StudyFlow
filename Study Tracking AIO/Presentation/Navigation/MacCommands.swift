//
//  MacCommands.swift
//  StudyOS
//
//  Menu bar commands for the Mac: a Go menu mirroring the iOS tabs, and
//  File actions that drive the same AppState presentation flags as the
//  in-app toolbar buttons.
//

import SwiftUI

#if os(macOS)
struct MacCommands: Commands {
    let appState: AppState

    var body: some Commands {
        CommandGroup(after: .newItem) {
            // ⇧⌘N instead of ⌘N: the system reserves ⌘N for New Window.
            Button("New Task…") {
                appState.isQuickAddPresented = true
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])

            Button("Scan Document…") {
                appState.isScanPresented = true
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
        }

        CommandMenu("Go") {
            ForEach(AppTab.allCases) { tab in
                if let key = tab.goShortcutKey {
                    Button("Go to \(tab.rawValue)") {
                        appState.selectedTab = tab
                    }
                    .keyboardShortcut(key, modifiers: .command)
                }
            }

            Divider()

            Button("Study AI…") {
                appState.isStudyAIPresented = true
            }
            .keyboardShortcut("d", modifiers: .command)

            Button("Start Study Session") {
                appState.startStudySession(durationMinutes: 25)
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
        }

        CommandGroup(after: .appSettings) {
            Button("Settings…") {
                appState.isSettingsPresented = true
            }
            .keyboardShortcut(",")
        }
    }
}
#endif
