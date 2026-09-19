//
//  SettingsView.swift
//  StudyOS
//

import SwiftUI
import UserNotifications

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("Integrations") {
                    NavigationLink(destination: GoogleClassroomConfigView()) {
                        HStack {
                            Image(systemName: "graduationcap")
                                .foregroundStyle(.blue)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Google Classroom")
                                    .font(.body)
                                Text(GoogleClassroomService.shared.isConnected ? "Connected (Read-Only)" : "Not Connected")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .accessibilityIdentifier("settings.classroom")
                }

                Section("Reminders & Notifications") {
                    HStack {
                        Image(systemName: "bell.badge")
                            .foregroundStyle(.tint)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notifications")
                                .font(.body)
                            Text(notificationStatusText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if notificationStatus == .notDetermined {
                            Button("Enable") {
                                Task {
                                    _ = try? await NotificationManager.shared.requestAuthorization()
                                    await checkStatus()
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .accessibilityIdentifier("settings.notifications.enable")
                        }
                    }
                }

                Section("Privacy & Data") {
                    NavigationLink(destination: PrivacyView()) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundStyle(.green)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Privacy & Security")
                                    .font(.body)
                                Text("On-device storage, Keychain, data deletion")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    NavigationLink(destination: DiagnosticsView()) {
                        HStack {
                            Image(systemName: "waveform.path.ecg")
                                .foregroundStyle(.orange)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Diagnostics & Self-Tests")
                                    .font(.body)
                                Text("Run verification suite & export data")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Self.versionString)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await checkStatus()
            }
        }
    }

    private static var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var notificationStatusText: String {
        switch notificationStatus {
        case .authorized: return "Enabled (Due soon, Overdue, Study sessions)"
        case .denied: return "Disabled in iOS Settings"
        case .notDetermined: return "Not yet requested"
        case .provisional: return "Enabled (quiet)"
        case .ephemeral: return "Enabled (temporary)"
        @unknown default: return "Unknown"
        }
    }

    private func checkStatus() async {
        let status = await NotificationManager.shared.checkAuthorizationStatus()
        await MainActor.run {
            self.notificationStatus = status
        }
    }
}
