//
//  SessionCompletionSheet.swift
//  StudyOS
//

import SwiftUI
import SwiftData

public struct SessionCompletionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    public let assignment: Assignment?
    public let durationStudiedMinutes: Int
    public let onContinueSession: () -> Void
    public let onFinishSession: () -> Void

    @State private var isRescheduling: Bool = false
    @State private var newDueDate: Date = Date().addingTimeInterval(86400)

    public init(
        assignment: Assignment?,
        durationStudiedMinutes: Int,
        onContinueSession: @escaping () -> Void,
        onFinishSession: @escaping () -> Void
    ) {
        self.assignment = assignment
        self.durationStudiedMinutes = durationStudiedMinutes
        self.onContinueSession = onContinueSession
        self.onFinishSession = onFinishSession
    }

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(.largeTitle))
                            .foregroundStyle(.tint)

                        Text("Study Session Finished")
                            .font(.title2.weight(.bold))

                        Text("You logged \(durationStudiedMinutes) minutes of focused study\(assignment != nil ? " on \(assignment!.title)" : "").")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }

                if let assignment = assignment {
                    Section("Assignment Status") {
                        Text("Would you like to mark \"\(assignment.title)\" as complete, continue studying, or reschedule?")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Button {
                            markComplete(assignment)
                        } label: {
                            Label("Mark Assignment Complete", systemImage: "checkmark.circle.fill")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.green)
                        }
                        .accessibilityIdentifier("session.complete")

                        Button {
                            onContinueSession()
                            dismiss()
                        } label: {
                            Label("Continue Studying (+15 min)", systemImage: "plus.circle")
                        }

                        Button {
                            newDueDate = assignment.dueDate
                            isRescheduling = true
                        } label: {
                            Label("Reschedule Due Date", systemImage: "clock.arrow.2.circlepath")
                        }
                    }
                } else {
                    Section("Next Step") {
                        Button {
                            onContinueSession()
                            dismiss()
                        } label: {
                            Label("Continue Another Session (+15 min)", systemImage: "plus.circle")
                        }
                    }
                }

                Section {
                    Button("Finish & Close") {
                        onFinishSession()
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("session.finish")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Session Summary")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isRescheduling) {
                NavigationStack {
                    Form {
                        DatePicker("New Due Date", selection: $newDueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                    .navigationTitle("Reschedule Assignment")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { isRescheduling = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if let assignment = assignment {
                                assignment.dueDate = newDueDate
                                assignment.updatedAt = Date()
                                try? modelContext.save()
                                WidgetSnapshotWriter.reload(context: modelContext)
                            }
                                isRescheduling = false
                                onFinishSession()
                                dismiss()
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }

    private func markComplete(_ assignment: Assignment) {
        assignment.status = .completed
        try? modelContext.saveOrThrow()
        WidgetSnapshotWriter.reload(context: modelContext)
        Task {
            await NotificationManager.shared.cancelAssignmentReminders(for: assignment.id)
        }
        onFinishSession()
        dismiss()
    }
}
