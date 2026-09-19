//
//  Haptics.swift
//  StudyOS
//

import UIKit

/// Central haptic feedback for consequential interactions only: completions,
/// deletions, timer controls, and primary actions. Uses UIKit feedback
/// generators, which respect the user's System Haptics setting automatically.
/// Not used on every tap — see the product interaction guidelines.
@MainActor
public enum Haptics {
    /// Light tap for primary button presses (Start Session, flip card).
    public static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Selection changed (toggle, picker, segmented control).
    public static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// Task succeeded (assignment completed, quiz answer correct, session saved).
    public static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Destructive or failed outcome (delete, quiz answer wrong).
    public static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
