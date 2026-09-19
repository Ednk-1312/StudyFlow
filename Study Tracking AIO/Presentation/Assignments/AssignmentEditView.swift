//
//  AssignmentEditView.swift
//  StudyOS
//

import SwiftUI
import SwiftData
public struct AssignmentEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private var assignmentToEdit: Assignment?

    @State private var title: String = ""
    @State private var subject: String = ""
    @State private var dueDate: Date = Date().addingTimeInterval(86400)
    @State private var estimatedMinutes: Int = 45
    @State private var priority: AssignmentPriority = .medium
    @State private var status: AssignmentStatus = .notStarted
    @State private var notes: String = ""

    public init(assignment: Assignment? = nil) {
        self.assignmentToEdit = assignment
        if let a = assignment {
            _title = State(initialValue: a.title)
            _subject = State(initialValue: a.courseName)
            _dueDate = State(initialValue: a.dueDate)
            _estimatedMinutes = State(initialValue: a.estimatedMinutes)
            _priority = State(initialValue: a.priority)
            _status = State(initialValue: a.status)
            _notes = State(initialValue: a.notes)
        }
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Title", text: $title)
                        .accessibilityIdentifier("assignment.title")
                    TextField("Class / Course", text: $subject)
                        .accessibilityIdentifier("assignment.subject")
                }

                Section("Due Date & Time") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    Stepper("Estimated Time: \(estimatedMinutes) min", value: $estimatedMinutes, in: 5...360, step: 15)
                }

                Section("Priority & Status") {
                    Picker("Priority", selection: $priority) {
                        ForEach(AssignmentPriority.allCases, id: \.self) { p in
                            Label(p.rawValue, systemImage: StudyOSTheme.priorityIcon(for: p)).tag(p)
                        }
                    }

                    Picker("Status", selection: $status) {
                        ForEach(AssignmentStatus.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                }

                Section("Notes & Instructions") {
                    TextField("Notes, submission links, instructions", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissibleKeyboard()
            .navigationTitle(assignmentToEdit == nil ? "New Assignment" : "Edit Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAssignment()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || subject.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityIdentifier("assignment.save")
                }
            }
        }
    }

    private func saveAssignment() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = assignmentToEdit {
            existing.title = cleanTitle
            existing.subject = cleanSubject
            existing.courseName = cleanSubject
            existing.dueDate = dueDate
            existing.estimatedMinutes = estimatedMinutes
            existing.priority = priority
            existing.status = status
            existing.notes = notes
            existing.updatedAt = Date()

            Task {
                if existing.status == .completed {
                    await NotificationManager.shared.cancelAssignmentReminders(for: existing.id)
                } else {
                    try? await NotificationManager.shared.scheduleAssignmentReminders(for: existing)
                }
                SpotlightIndexer.shared.indexAssignment(existing)
            }
        } else {
            let newAssignment = Assignment(
                title: cleanTitle,
                subject: cleanSubject,
                courseName: cleanSubject,
                dueDate: dueDate,
                estimatedMinutes: estimatedMinutes,
                priority: priority,
                status: status,
                notes: notes,
                source: .manual
            )
            AssignmentStore.shared.saveNew(newAssignment, in: modelContext)
        }

        try? modelContext.saveOrThrow()
        WidgetSnapshotWriter.reload(context: modelContext)
        dismiss()
    }
}
