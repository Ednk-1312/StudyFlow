//
//  OnboardingView.swift
//  StudyOS
//

import SwiftUI
import UserNotifications

/// Brief first-launch introduction: what StudyOS does, one contextual
/// notification request, and an immediate way in. Never blocks the app —
/// "Get Started" is always available.
struct OnboardingView: View {
    @Binding var isPresented: Bool

    @State private var isRequestingNotifications = false
    @State private var notificationsGranted: Bool? = nil

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("StudyOS")
                            .font(.largeTitle.weight(.bold))
                        Text("Plan assignments, scan worksheets, organize study materials, and time your study sessions. Everything is stored on this device.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                Section("Reminders") {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "bell.badge")
                            .foregroundStyle(.tint)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Get reminders before assignments are due.")
                                .font(.subheadline)
                            if let granted = notificationsGranted {
                                Label(granted ? "Reminders enabled" : "Reminders off — you can enable them in Settings",
                                      systemImage: granted ? "checkmark.circle" : "bell.slash")
                                    .font(.caption)
                                    .foregroundStyle(granted ? .green : .secondary)
                            } else {
                                Button {
                                    requestNotifications()
                                } label: {
                                    if isRequestingNotifications {
                                        ProgressView()
                                    } else {
                                        Text("Enable Reminders")
                                    }
                                }
                                .disabled(isRequestingNotifications)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                Section("Google Classroom") {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "graduationcap")
                            .foregroundStyle(.tint)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Import classes and coursework automatically. Read-only, and completely optional — skip it and everything in StudyOS still works.")
                                .font(.subheadline)
                            Text("You can connect later in Settings.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }

                Section {
                    Text("Your assignments, notes, and documents stay on this device. Nothing is uploaded.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Get Started") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func requestNotifications() {
        isRequestingNotifications = true
        Task {
            let granted = (try? await NotificationManager.shared.requestAuthorization()) ?? false
            await MainActor.run {
                notificationsGranted = granted
                isRequestingNotifications = false
            }
        }
    }
}
