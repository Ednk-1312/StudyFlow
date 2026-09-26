//
//  Study_Tracking_AIOApp.swift
//  StudyOS
//

import SwiftUI
import SwiftData

@main
struct Study_Tracking_AIOApp: App {
    let container: ModelContainer
    @State private var appState = AppState.shared
    @State private var preferences = AppPreferences.shared
    @State private var isOnboardingPresented = false

    /// UI tests launch with this argument to clear all local data and skip
    /// onboarding, giving every test a deterministic fresh install.
    static let uiTestResetArgument = "-uitest-reset"

    init() {
        if CommandLine.arguments.contains(Self.uiTestResetArgument) {
            Self.destroyPersistentStores()
        }
        self.container = StudyOSSchema.createModelContainer()
        if CommandLine.arguments.contains("-run-tests") {
            Task {
                do {
                    let result = try await StudyOSTestSuite.runAllTests()
                    print("[StudyOSTests] ALL \(result.passed)/\(result.total) TEST SUITES PASSED CLEANLY")
                    fflush(stdout)
                    exit(0)
                } catch {
                    print("[StudyOSTests] TEST FAILURE: \(error.localizedDescription)")
                    fflush(stdout)
                    exit(1)
                }
            }
        }

        // Deep-link and inspection CLI arguments
        if let tabIndex = CommandLine.arguments.firstIndex(of: "-tab"), tabIndex + 1 < CommandLine.arguments.count {
            let tabArg = CommandLine.arguments[tabIndex + 1].lowercased()
            switch tabArg {
            case "assignments": appState.selectedTab = .assignments
            case "planner": appState.selectedTab = .planner
            case "materials": appState.selectedTab = .materials
            case "studyai": appState.isStudyAIPresented = true
            case "utilities": appState.selectedTab = .utilities
            case "settings": appState.isSettingsPresented = true
            default: break
            }
        }
        if CommandLine.arguments.contains("-quick-add") {
            appState.isQuickAddPresented = true
        }
        if CommandLine.arguments.contains("-scan") {
            appState.isScanPresented = true
        }
        if CommandLine.arguments.contains("-session") {
            appState.startStudySession(durationMinutes: 25)
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(appState)
#if os(macOS)
                .sheet(isPresented: $isOnboardingPresented) {
                    OnboardingView(isPresented: $isOnboardingPresented)
                        .interactiveDismissDisabled() // first-run: require an explicit choice
                        .macSheetSizing()
                }
#else
                .fullScreenCover(isPresented: $isOnboardingPresented) {
                    OnboardingView(isPresented: $isOnboardingPresented)
                }
#endif
                .onAppear {
                    if CommandLine.arguments.contains(Self.uiTestResetArgument) {
                        // Fresh-install simulation: onboarding shows, tests dismiss it.
                        preferences.hasCompletedOnboarding = false
                    }
                    if !preferences.hasCompletedOnboarding && !CommandLine.arguments.contains("-run-tests") {
                        isOnboardingPresented = true
                        preferences.hasCompletedOnboarding = true
                    }
                }
#if os(macOS)
                .frame(minWidth: 720, minHeight: 480)
#endif
        }
        .modelContainer(container)
#if os(macOS)
        .commands {
            MacCommands(appState: appState)
        }
#endif
    }

    /// Deletes the on-disk SwiftData store so a UI test run starts from a
    /// clean slate. Only ever called from the UI-test launch path.
    private static func destroyPersistentStores() {
        let url = StudyOSSchema.storeURL
        for suffix in ["", "-wal", "-shm"] {
            let fileURL = url.deletingLastPathComponent().appendingPathComponent(url.lastPathComponent + suffix)
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
}
