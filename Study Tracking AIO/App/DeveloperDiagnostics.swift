//
//  DeveloperDiagnostics.swift
//  StudyOS
//

import Foundation
import SwiftData
import CoreSpotlight
import UserNotifications

/// A single developer-diagnostic fact: a label plus a developer-facing value.
/// Values must never contain secrets (tokens, credentials, document contents).
public struct DiagnosticEntry: Identifiable, Equatable {
    public let id: UUID
    public let label: String
    public let value: String
    public let state: State

    public enum State: Equatable {
        case ok
        case warning
        case inactive
    }

    public init(label: String, value: String, state: State) {
        self.id = UUID()
        self.label = label
        self.value = value
        self.state = state
    }
}

/// Collects developer-facing technical state for the Diagnostics screen.
/// This is the only place build/configuration specifics are surfaced, and it
/// deliberately reports booleans and enums — never credentials or content.
public enum DeveloperDiagnostics {

    // MARK: - Google OAuth / Classroom

    /// Build-configuration facts about the Google integration. For developers.
    public static func googleOAuthEntries() -> [DiagnosticEntry] {
        let configured = GoogleClassroomService.shared.isConfigured
        let connected = GoogleClassroomService.shared.isConnected

        var entries: [DiagnosticEntry] = [
            DiagnosticEntry(
                label: "OAuth client credentials",
                value: configured ? "Present in Info.plist" : "Missing from Info.plist (GoogleClientID / GoogleRedirectURI)",
                state: configured ? .ok : .inactive
            ),
            DiagnosticEntry(
                label: "Authorization state",
                value: connected ? "Tokens present in Keychain" : "No tokens in Keychain",
                state: connected ? .ok : .inactive
            )
        ]

        if connected {
            entries.append(DiagnosticEntry(
                label: "Access token state",
                value: GoogleClassroomService.shared.needsReauthorization ? "Expired; refresh unavailable or failed" : "Valid or silently refreshable",
                state: GoogleClassroomService.shared.needsReauthorization ? .warning : .ok
            ))
        }

        return entries
    }

    // MARK: - Sync

    public static func syncEntries(engine: SyncEngine) -> [DiagnosticEntry] {
        let formatter = { () -> DateFormatter in
            let f = DateFormatter()
            f.dateStyle = .short
            f.timeStyle = .medium
            return f
        }()

        let stateName: String
        let stateKind: DiagnosticEntry.State
        switch engine.syncStatus {
        case .idle:
            stateName = "idle"
            stateKind = .inactive
        case .syncing:
            stateName = "syncing"
            stateKind = .ok
        case .success:
            stateName = "success"
            stateKind = .ok
        case .failed:
            stateName = "failed"
            stateKind = .warning
        case .offline:
            stateName = "offline"
            stateKind = .warning
        case .authenticationRequired:
            stateName = "authenticationRequired"
            stateKind = .warning
        }

        var entries: [DiagnosticEntry] = [
            DiagnosticEntry(label: "Sync state", value: stateName, state: stateKind),
            DiagnosticEntry(
                label: "Last sync attempt",
                value: engine.lastSyncAttemptDate.map(formatter.string) ?? "Never",
                state: engine.lastSyncAttemptDate == nil ? .inactive : .ok
            ),
            DiagnosticEntry(
                label: "Last successful sync",
                value: engine.lastSuccessfulSyncDate.map(formatter.string) ?? "Never",
                state: engine.lastSuccessfulSyncDate == nil ? .inactive : .ok
            )
        ]

        if let error = engine.lastSyncError {
            entries.append(DiagnosticEntry(label: "Last sync error", value: error, state: .warning))
        }

        return entries
    }

    // MARK: - Storage & Database Health

    public static func storageEntries(context: ModelContext) -> [DiagnosticEntry] {
        var entries: [DiagnosticEntry] = []

        do {
            let assignments = try context.fetchCount(FetchDescriptor<Assignment>())
            let courses = try context.fetchCount(FetchDescriptor<Course>())
            let sessions = try context.fetchCount(FetchDescriptor<StudySession>())
            let materials = try context.fetchCount(FetchDescriptor<Material>())
            let exams = try context.fetchCount(FetchDescriptor<ExamEvent>())
            let reminders = try context.fetchCount(FetchDescriptor<Reminder>())

            entries.append(DiagnosticEntry(label: "Assignments", value: "\(assignments)", state: .ok))
            entries.append(DiagnosticEntry(label: "Courses", value: "\(courses)", state: .ok))
            entries.append(DiagnosticEntry(label: "Study sessions", value: "\(sessions)", state: .ok))
            entries.append(DiagnosticEntry(label: "Materials", value: "\(materials)", state: .ok))
            entries.append(DiagnosticEntry(label: "Exams & events", value: "\(exams)", state: .ok))
            entries.append(DiagnosticEntry(label: "Reminders", value: "\(reminders)", state: .ok))

            let bytes = LocalStorageManager.shared.totalStorageUsageBytes()
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useKB, .useMB, .useGB]
            formatter.countStyle = .file
            entries.append(DiagnosticEntry(label: "Material files on disk", value: formatter.string(fromByteCount: bytes), state: .ok))
        } catch {
            entries.append(DiagnosticEntry(label: "Database health", value: "Fetch failed: \(error.localizedDescription)", state: .warning))
        }

        return entries
    }

    // MARK: - Spotlight Indexing

    public static func indexingStatusEntry() -> DiagnosticEntry {
        // The searchable index contents cannot be fetched via public API,
        // so diagnostics report whether indexing is available on this device.
        if CSSearchableIndex.isIndexingAvailable() {
            return DiagnosticEntry(label: "Spotlight indexing", value: "Available", state: .ok)
        }
        return DiagnosticEntry(label: "Spotlight indexing", value: "Unavailable on this device", state: .inactive)
    }

    // MARK: - Notification Authorization

    public static func notificationEntry(authorizationStatus: UNAuthorizationStatus) -> DiagnosticEntry {
        let name: String
        switch authorizationStatus {
        case .notDetermined: name = "notDetermined"
        case .denied: name = "denied"
        case .authorized: name = "authorized"
        case .provisional: name = "provisional"
        case .ephemeral: name = "ephemeral"
        @unknown default: name = "unknown"
        }
        return DiagnosticEntry(label: "Notification authorization", value: name, state: authorizationStatus == .authorized ? .ok : .inactive)
    }
}
