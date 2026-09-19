//
//  Theme.swift
//  StudyOS
//

import SwiftUI

public enum StudyOSTheme {
    // Semantic Subject Colors (subtle, colorblind-safe)
    public static func subjectColor(for subject: String) -> Color {
        let lower = subject.lowercased()
        if lower.contains("math") || lower.contains("calc") || lower.contains("algebra") {
            return .blue
        } else if lower.contains("bio") || lower.contains("chem") || lower.contains("phys") || lower.contains("science") {
            return .green
        } else if lower.contains("hist") || lower.contains("gov") || lower.contains("econ") {
            return .orange
        } else if lower.contains("eng") || lower.contains("lit") || lower.contains("write") {
            return .purple
        } else if lower.contains("span") || lower.contains("french") || lower.contains("lang") {
            return .teal
        } else if lower.contains("cs") || lower.contains("comp") || lower.contains("code") {
            return .indigo
        } else {
            return .secondary
        }
    }

    public static func priorityColor(for priority: AssignmentPriority) -> Color {
        switch priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .secondary
        }
    }

    public static func priorityIcon(for priority: AssignmentPriority) -> String {
        switch priority {
        case .urgent: return "exclamationmark.3"
        case .high: return "exclamationmark.2"
        case .medium: return "exclamationmark"
        case .low: return "arrow.down"
        }
    }
}
