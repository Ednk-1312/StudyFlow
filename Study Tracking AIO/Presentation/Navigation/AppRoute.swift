//
//  AppRoute.swift
//  StudyOS
//

import Foundation

public enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home = "Today"
    case assignments = "Assignments"
    case planner = "Planner"
    case materials = "Materials"
    case utilities = "Tools"

    public var id: String { rawValue }

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
