//
//  Haptics.swift
//  StudyOS
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Central haptic feedback for consequential interactions only: completions,
/// deletions, timer controls, and primary actions. Uses UIKit feedback
/// generators on iOS and AppKit's haptic manager on macOS, both of which
/// respect the user's system haptic preferences automatically.
/// Not used on every tap — see the product interaction guidelines.
@MainActor
public enum Haptics {
    /// Light tap for primary button presses (Start Session, flip card).
    public static func tap() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #elseif canImport(AppKit)
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        #endif
    }

    /// Selection changed (toggle, picker, segmented control).
    public static func selection() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #elseif canImport(AppKit)
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        #endif
    }

    /// Task succeeded (assignment completed, quiz answer correct, session saved).
    public static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #elseif canImport(AppKit)
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        #endif
    }

    /// Destructive or failed outcome (delete, quiz answer wrong).
    public static func warning() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #elseif canImport(AppKit)
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        #endif
    }
}
