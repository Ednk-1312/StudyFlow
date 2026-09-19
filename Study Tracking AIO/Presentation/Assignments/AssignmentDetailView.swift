//
//  AssignmentDetailView.swift
//  StudyOS
//

import SwiftUI
import SwiftData

public struct AssignmentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    public let assignment: Assignment

    @State private var isEditing: Bool = false
    @State private var isDeleteConfirmationPresented: Bool = false
    @State private var isRescheduleSheetPresented: Bool = false
    @State private var newRescheduleDate: Date = Date()

    @Query private var allMaterials: [Material]

    public init(assignment: Assignment) {
        self.assignment = assignment
    }

    private var linkedMaterials: [Material] {
        allMaterials.filter { assignment.materialIDs.contains($0.id) }
    }

    public var body: some View {
        List {
            // 1. Status & Actions
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        SubjectTag(subject: assignment.courseName)
                        Spacer()
                        PriorityBadge(priority: assignment.priority)
                    }

                    Text(assignment.title)
                        .font(.title2.weight(.bold))

                    HStack(spacing: 12) {
                        StatusPill(status: assignment.status)
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Label("\(assignment.estimatedMinutes) min estimated", systemImage: "timer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)

                // Quick Action Buttons
                HStack(spacing: 12) {
                    Button {
                        toggleCompletion()
                    } label: {
                        Label(
                            assignment.status == .completed ? "Mark Incomplete" : "Mark Complete",
                            systemImage: assignment.status == .completed ? "arrow.uturn.backward" : "checkmark"
                        )
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(assignment.status == .completed ? .secondary : .green)
                    .accessibilityIdentifier("detail.complete")

                    Button {
                        appState.startStudySession(for: assignment, durationMinutes: min(assignment.estimatedMinutes, 45))
                    } label: {
                        Label("Study", systemImage: "play.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 4)
            }

            // 2. Schedule & Reminders
            Section("Schedule") {
                HStack {
                    Label("Due Date", systemImage: "calendar")
                    Spacer()
                    Text(DateFormatter.localizedString(from: assignment.dueDate, dateStyle: .medium, timeStyle: .short))
                        .foregroundStyle(assignment.status == .overdue ? .red : .secondary)
                }

                Button {
                    newRescheduleDate = assignment.dueDate
                    isRescheduleSheetPresented = true
                } label: {
                    Label("Reschedule Due Date", systemImage: "clock.arrow.2.circlepath")
                }
                .accessibilityIdentifier("detail.reschedule")
            }

            // 3. Notes
            if !assignment.notes.isEmpty {
                Section("Notes & Instructions") {
                    Text(assignment.notes)
                        .font(.body)
                        .textSelection(.enabled)
                }
            }

            // 4. Associated Materials
            Section("Attached Materials (\(linkedMaterials.count))") {
                if linkedMaterials.isEmpty {
                    Text("No documents or study notes attached.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(linkedMaterials) { material in
                        NavigationLink(destination: MaterialDetailView(material: material)) {
                            HStack {
                                Image(systemName: material.fileType.systemImage)
                                    .foregroundStyle(.tint)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(material.title)
                                        .font(.body)
                                    Text(material.fileType.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            // 5. Metadata & Source
            Section("Details") {
                HStack {
                    Text("Source")
                    Spacer()
                    Text(assignment.source.rawValue)
                        .foregroundStyle(.secondary)
                }

                if let synced = assignment.lastSyncedAt {
                    HStack {
                        Text("Last Synced")
                        Spacer()
                        Text(DateFormatter.localizedString(from: synced, dateStyle: .short, timeStyle: .short))
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Text("Created")
                    Spacer()
                    Text(DateFormatter.localizedString(from: assignment.createdAt, dateStyle: .short, timeStyle: .none))
                        .foregroundStyle(.secondary)
                }
            }

            // 6. Destructive Actions
            Section {
                Button(role: .destructive) {
                    isDeleteConfirmationPresented = true
                } label: {
                    Label("Delete Assignment", systemImage: "trash")
                }
                .accessibilityIdentifier("detail.delete")
            }
        }
        .navigationTitle("Assignment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            AssignmentEditView(assignment: assignment)
        }
        .sheet(isPresented: $isRescheduleSheetPresented) {
            NavigationStack {
                Form {
                    DatePicker("New Due Date", selection: $newRescheduleDate, displayedComponents: [.date, .hourAndMinute])
                }
                .navigationTitle("Reschedule")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { isRescheduleSheetPresented = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Apply") {
                            assignment.dueDate = newRescheduleDate
                            assignment.updatedAt = Date()
                            try? modelContext.saveOrThrow()
                            WidgetSnapshotWriter.reload(context: modelContext)
                            Task {
                                try? await NotificationManager.shared.scheduleAssignmentReminders(for: assignment)
                            }
                            isRescheduleSheetPresented = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .confirmationDialog(
            "Delete Assignment?",
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteAssignment()
            }
            .accessibilityIdentifier("detail.deleteConfirm")
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \"\(assignment.title)\" and cancel all associated reminders.")
        }
    }

    private func toggleCompletion() {
        let undo = AssignmentStore.shared.toggleCompletion(of: assignment, in: modelContext)
        appState.showUndoToast(message: assignment.status == .completed ? "Completed \"\(assignment.title)\"" : "Marked incomplete") {
            undo()
        }
    }

    private func deleteAssignment() {
        let undo = AssignmentStore.shared.delete(assignment, in: modelContext)
        _ = undo
        dismiss()
    }
}
