//
//  GoogleClassroomConfigView.swift
//  StudyOS
//

import SwiftUI
import SwiftData

/// Settings > Google Classroom. Classroom is optional: the copy here never
/// gates core functionality and never exposes developer diagnostics such as
/// missing OAuth credentials — that information lives in Settings >
/// Diagnostics for development builds only.
public struct GoogleClassroomConfigView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var isConnected: Bool = GoogleClassroomService.shared.isConnected
    @State private var isSyncing: Bool = false
    @State private var currentSyncStatus: SyncStatus = .idle
    @State private var isDisconnectAlertPresented: Bool = false
    @State private var connectionError: String? = nil

    public init() {}

    public var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Google Classroom")
                        .font(.headline)
                    Text("Connect your school Google account to import your classes and coursework. StudyOS reads course names and assignment details only.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Connection") {
                HStack {
                    Text("Status")
                    Spacer()
                    Label {
                        Text(isConnected ? "Connected" : "Not connected")
                    } icon: {
                        Image(systemName: isConnected ? "checkmark.circle.fill" : "circle.dashed")
                            .foregroundStyle(isConnected ? .green : .secondary)
                    }
                }
                .accessibilityElement(children: .combine)

                if isConnected {
                    if let lastSync = SyncEngine.shared.lastSuccessfulSyncDate {
                        HStack {
                            Text("Last Successful Sync")
                            Spacer()
                            Text(DateFormatter.localizedString(from: lastSync, dateStyle: .short, timeStyle: .short))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        triggerSync()
                    } label: {
                        HStack {
                            Text(isSyncing ? "Syncing…" : "Sync Now")
                            Spacer()
                            if isSyncing {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                        }
                    }
                    .disabled(isSyncing)

                    if let message = statusMessage {
                        Label(message.text, systemImage: message.systemImage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if !currentSyncStatus.isSyncing, case .authenticationRequired = currentSyncStatus {
                        Button("Reauthorize Google Classroom") {
                            reconnect()
                        }
                    }

                    Button(role: .destructive) {
                        isDisconnectAlertPresented = true
                    } label: {
                        Text("Disconnect Google Classroom")
                    }
                } else {
                    // No configured-credential branch in user UI. The button
                    // always appears; if the build lacks OAuth configuration
                    // the attempt surfaces a user-safe explanation below.
                    Button {
                        connectClassroom()
                    } label: {
                        Label("Connect Google Classroom", systemImage: "link")
                            .font(.body.weight(.semibold))
                    }

                    if let connectionError {
                        Label(connectionError, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your other StudyOS features work without it.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("Read-only permissions: your course list and coursework. No Gmail, Drive, Calendar, or Contacts. Nothing is written back to Classroom.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }

            if isConnected {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Read-only permissions")
                            .font(.subheadline.weight(.medium))
                        Text("StudyOS requests two Classroom scopes: your course list and your coursework. It never requests Gmail, Drive, Calendar, or Contacts, and it never writes back to Classroom.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Sign-in tokens are stored in this device's Keychain. Syncing requires an internet connection; your saved assignments remain available offline.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Google Classroom")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Disconnect Google Classroom?",
            isPresented: $isDisconnectAlertPresented,
            titleVisibility: .visible
        ) {
            Button("Disconnect", role: .destructive) {
                disconnectClassroom()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your saved assignments stay on this device. Coursework won't be imported until you reconnect.")
        }
        .onAppear {
            currentSyncStatus = SyncEngine.shared.syncStatus
        }
    }

    private var statusMessage: (text: String, systemImage: String)? {
        switch currentSyncStatus {
        case .idle:
            return nil
        case .syncing:
            return (currentSyncStatus.displayMessage, "arrow.triangle.2.circlepath")
        case .success:
            return (currentSyncStatus.displayMessage, "checkmark.circle")
        case .failed:
            return (currentSyncStatus.displayMessage, "exclamationmark.triangle")
        case .offline:
            return (currentSyncStatus.displayMessage, "wifi.slash")
        case .authenticationRequired:
            return (currentSyncStatus.displayMessage, "lock.trianglebadge.exclamationmark")
        }
    }

    private func connectClassroom() {
        connectionError = nil
        Task {
            do {
                _ = try await GoogleClassroomService.shared.authenticate()
                await MainActor.run {
                    isConnected = GoogleClassroomService.shared.isConnected
                }
            } catch let error as GoogleClassroomError {
                await MainActor.run {
                    // Only GoogleClassroomError carries reviewed, user-safe
                    // copy. Anything unexpected becomes a generic-but-honest
                    // message rather than raw diagnostics.
                    connectionError = error.errorDescription
                }
            } catch {
                await MainActor.run {
                    connectionError = "StudyOS couldn't reach Google sign-in. Check your connection and try again."
                }
            }
        }
    }

    private func reconnect() {
        connectionError = nil
        Task {
            do {
                _ = try await GoogleClassroomService.shared.authenticate()
                await MainActor.run {
                    isConnected = GoogleClassroomService.shared.isConnected
                    currentSyncStatus = .idle
                }
            } catch let error as GoogleClassroomError {
                await MainActor.run {
                    connectionError = error.errorDescription
                }
            } catch {
                await MainActor.run {
                    connectionError = "StudyOS couldn't reach Google sign-in. Check your connection and try again."
                }
            }
        }
    }

    private func disconnectClassroom() {
        Task {
            await GoogleClassroomService.shared.disconnect()
            await MainActor.run {
                isConnected = false
                currentSyncStatus = .idle
            }
        }
    }

    private func triggerSync() {
        isSyncing = true
        Task {
            await SyncEngine.shared.performSync(modelContext: modelContext)
            await MainActor.run {
                isSyncing = false
                currentSyncStatus = SyncEngine.shared.syncStatus
            }
        }
    }
}
