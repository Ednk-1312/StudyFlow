//
//  PrivacyView.swift
//  StudyOS
//

import SwiftUI
import SwiftData
import UserNotifications

/// Settings > Privacy. Every claim on this screen must match actual behavior:
/// AI study tools run on-device via Apple's NaturalLanguage framework, and
/// Google Classroom is the single optional third-party connection.
public struct PrivacyView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var isDeleteAllConfirmationPresented: Bool = false
    @State private var documentsStorageBytes: Int64 = LocalStorageManager.shared.totalStorageUsageBytes()
    @State private var isClassroomConnected: Bool = GoogleClassroomService.shared.isConnected
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var deleteError: String?

    public init() {}

    public var body: some View {
        List {
            dataStorageSection

            googleClassroomSection

            aiProcessingSection

            notificationsSection

            permissionsSection

            privacyPrinciplesSection

            deleteSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete All Local Data?",
            isPresented: $isDeleteAllConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete Everything", role: .destructive) {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Assignments, courses, materials, sessions, and reminders will be permanently erased from this device. This cannot be undone.")
        }
        .alert("Couldn't Delete Some Data", isPresented: .init(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteError ?? "")
        }
        .task {
            notificationStatus = await NotificationManager.shared.checkAuthorizationStatus()
        }
        .onAppear {
            documentsStorageBytes = LocalStorageManager.shared.totalStorageUsageBytes()
            isClassroomConnected = GoogleClassroomService.shared.isConnected
        }
    }

    // MARK: - Sections

    private var dataStorageSection: some View {
        Section {
            HStack {
                Image(systemName: "internaldrive")
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Local Data")
                        .font(.body.weight(.medium))
                    Text("Your StudyOS assignments, planner data, imported materials, and study history are stored on your device by default.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)

            HStack {
                Text("Imported material files")
                Spacer()
                Text(formattedBytes(documentsStorageBytes))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        } header: {
            Text("Data Storage")
        }
    }

    private var googleClassroomSection: some View {
        Section {
            HStack {
                Image(systemName: "graduationcap")
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(isClassroomConnected ? "Connected — read-only" : "Not connected")
                        .font(.body.weight(.medium))
                    Text(isClassroomConnected
                         ? "StudyOS reads your course list and coursework from Google when you sync. Nothing is written to Classroom."
                         : "Optional. When connected, syncing reads your course list and coursework from Google.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)

            NavigationLink(destination: GoogleClassroomConfigView()) {
                Text("Manage Google Classroom")
            }
        } header: {
            Text("Google Classroom")
        }
    }

    private var aiProcessingSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Label("On-device processing", systemImage: "iphone.gen3")
                    .font(.body.weight(.medium))
                Text("Summaries, explanations, flashcards, and quizzes are generated on this device with Apple's NaturalLanguage framework. Your material text is not sent to StudyOS or to third-party AI services.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("AI output is a study aid, not authoritative school data. Check it against your materials.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
        } header: {
            Text("AI Processing")
        }
    }

    private var notificationsSection: some View {
        Section {
            HStack {
                Image(systemName: "bell.badge")
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Local reminders")
                        .font(.body.weight(.medium))
                    Text(notificationPrivacyText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
        } header: {
            Text("Notifications")
        }
    }

    private var notificationPrivacyText: String {
        switch notificationStatus {
        case .denied:
            return "Reminders are off in iOS Settings. StudyOS keeps working without them, and sends nothing to a server either way."
        default:
            return "Reminders are scheduled on this device with iOS notifications — no server is involved. Turn them off anytime in iOS Settings."
        }
    }

    private var permissionsSection: some View {
        Section {
            permissionRow(systemImage: "camera", title: "Camera",
                          detail: "Used only while scanning a worksheet. Text is extracted on this device.")
            permissionRow(systemImage: "photo.on.rectangle", title: "Photo Library",
                          detail: "Accessed only when you import a photo as a material.")
            permissionRow(systemImage: "folder", title: "Files",
                          detail: "Accessed only when you import a document.")
            permissionRow(systemImage: "location.slash", title: "Location & Local Network",
                          detail: "Not used. StudyOS never requests these.")
        } header: {
            Text("Permissions")
        } footer: {
            Text("StudyOS asks for camera, photo, or file access only when you use the matching feature.")
        }
    }

    private func permissionRow(systemImage: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var privacyPrinciplesSection: some View {
        Section {
            Label("No advertising or tracking SDKs", systemImage: "xmark.shield")
            Label("No analytics collection", systemImage: "xmark.shield")
            Label("No selling or sharing of your data", systemImage: "xmark.shield")
            Label("No account required", systemImage: "person.crop.circle.badge.checkmark")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    private var deleteSection: some View {
        Section {
            NavigationLink(destination: PrivacyPolicyView()) {
                Label("Privacy Policy", systemImage: "doc.plaintext")
            }

            Button(role: .destructive) {
                isDeleteAllConfirmationPresented = true
            } label: {
                Label("Delete All Local Data", systemImage: "trash")
            }
        } header: {
            Text("Policy & Data Management")
        } footer: {
            Text("Deleting removes assignments, courses, materials, sessions, and reminders from this device, and removes StudyOS items from Spotlight search.")
        }
    }

    // MARK: - Actions

    private func formattedBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func deleteAllData() {
        do {
            try modelContext.delete(model: Assignment.self)
            try modelContext.delete(model: Course.self)
            try modelContext.delete(model: StudySession.self)
            try modelContext.delete(model: Material.self)
            try modelContext.delete(model: Reminder.self)
            try modelContext.delete(model: ExamEvent.self)
            try modelContext.saveOrThrow()
        } catch {
            deleteError = "Part of your data couldn't be erased. Try again, or reinstall the app to remove everything."
            return
        }

        // File cleanup: enumerate and delete individually so one stubborn
        // file can't abort the rest of the wipe.
        let fileNames = materialsFileNames()
        for name in fileNames {
            try? LocalStorageManager.shared.deleteFile(relativeFileName: name)
        }

        KeychainService.shared.clearAll()
        SpotlightIndexer.shared.deindexAll()
        Task {
            await NotificationManager.shared.cancelAllNotifications()
        }

        documentsStorageBytes = LocalStorageManager.shared.totalStorageUsageBytes()
        isClassroomConnected = false
    }

    private func materialsFileNames() -> [String] {
        let directory = LocalStorageManager.shared.getFileUrl(relativeFileName: "")
            .deletingLastPathComponent()
            .appendingPathComponent("StudyOSMaterials")
        let items = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return items.map(\.lastPathComponent)
    }
}
