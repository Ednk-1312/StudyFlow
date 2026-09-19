//
//  SyncState.swift
//  StudyOS
//

import Foundation

public enum SyncStatus: Equatable, Sendable {
    case idle
    case syncing
    case success(Date)
    case failed(String)
    case offline
    case authenticationRequired

    public var isSyncing: Bool {
        if case .syncing = self { return true }
        return false
    }

    public var displayMessage: String {
        switch self {
        case .idle:
            return "Ready to sync"
        case .syncing:
            return "Syncing coursework..."
        case .success(let date):
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return "Synced \(formatter.localizedString(for: date, relativeTo: Date()))"
        case .failed(let message):
            return "Sync issue: \(message)"
        case .offline:
            return "Offline — saved assignments available"
        case .authenticationRequired:
            return "Google Classroom reauthorization required"
        }
    }

    public var systemImage: String {
        switch self {
        case .idle:
            return "arrow.triangle.2.circlepath"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        case .success:
            return "checkmark.circle"
        case .failed:
            return "exclamationmark.triangle"
        case .offline:
            return "wifi.slash"
        case .authenticationRequired:
            return "lock.trianglebadge.exclamationmark"
        }
    }
}
