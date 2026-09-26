//
//  AppRoute.swift
//  StudyOS
//

import Foundation
import SwiftUI

public enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home = "Today"
    case assignments = "Assignments"
    case planner = "Planner"
    case materials = "Materials"
    case utilities = "Tools"

    public var id: String { rawValue }

    /// Optional keyboard shortcut digit for the macOS Go menu (⌘1…⌘5).
    public var goShortcutKey: KeyEquivalent? {
        switch self {
        case .home: return "1"
        case .assignments: return "2"
        case .planner: return "3"
        case .materials: return "4"
        case .utilities: return "5"
        }
    }

    public var systemImage: String {
        switch self {
        case .home: return "text.badge.checkmark"
        case .assignments: return "checklist"
        case .planner: return "calendar"
        case .materials: return "folder"
        case .utilities: return "wrench.and.screwdriver"
        }
    }
}
