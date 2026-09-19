//
//  AppState.swift
//  StudyOS
//

import SwiftUI
import Observation

public struct ToastItem: Identifiable {
    public let id = UUID()
    public let message: String
    public let undoAction: () -> Void
}

@Observable
public final class AppState {
    public static let shared = AppState()

    public var selectedTab: AppTab = .home
    public var activeStudySessionAssignment: Assignment?
    public var isStudySessionActive: Bool = false
    public var activeSessionPlannedMinutes: Int = 25

    public var isQuickAddPresented: Bool = false
    public var isScanPresented: Bool = false
    public var isStudyAIPresented: Bool = false
    public var isSettingsPresented: Bool = false

    public var currentToast: ToastItem?

    /// Set when persisting a change fails. Surfaced in the UI; local data
    /// remains usable. Cleared when the user dismisses it.
    public var dataErrorMessage: String?

    public init() {}

    public func showUndoToast(message: String, action: @escaping () -> Void) {
        currentToast = ToastItem(message: message, undoAction: { [weak self] in
            action()
            self?.currentToast = nil
        })

        // Auto dismiss after 5 seconds
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if self?.currentToast?.message == message {
                self?.currentToast = nil
            }
        }
    }

    public func startStudySession(for assignment: Assignment? = nil, durationMinutes: Int = 25) {
        self.activeStudySessionAssignment = assignment
        self.activeSessionPlannedMinutes = durationMinutes
        self.isStudySessionActive = true
    }
}
