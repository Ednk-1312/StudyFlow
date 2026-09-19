//
//  QuickAddSheet.swift
//  StudyOS
//

import SwiftUI
import SwiftData

public struct QuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var entryType: EntryType = .assignment
    @State private var title: String = ""
    @State private var subject: String = ""
    @State private var dueDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var estimatedMinutes: Int = 45
    @State private var priority: AssignmentPriority = .medium
    @State private var notes: String = ""

    // Exam specific
    @State private var examType: ExamType = .test
    @State private var preparationDays: Int = 5

    public enum EntryType: String, CaseIterable {
        case assignment = "Assignment"
        case exam = "Exam / Quiz"
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $entryType) {
                        ForEach(EntryType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Details") {
                    TextField("Title", text: $title)
                        .accessibilityIdentifier("quickadd.title")
                    TextField("Subject / Class", text: $subject)
                        .accessibilityIdentifier("quickadd.subject")
                }

                if entryType == .assignment {
                    Section("Due Date & Effort") {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        Stepper("Estimated: \(estimatedMinutes) min", value: $estimatedMinutes, in: 5...360, step: 15)
                        Picker("Priority", selection: $priority) {
                            ForEach(AssignmentPriority.allCases, id: \.self) { p in
                                Label(p.rawValue, systemImage: StudyOSTheme.priorityIcon(for: p)).tag(p)
                            }
                        }
                    }
                } else {
                    Section("Exam Schedule") {
                        DatePicker("Exam Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        Picker("Exam Type", selection: $examType) {
                            ForEach(ExamType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        Stepper("Prep Window: \(preparationDays) days", value: $preparationDays, in: 1...30)
                    }
                }

                Section("Notes (Optional)") {
                    TextField("Additional notes or requirements", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissibleKeyboard()
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveItem()
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || subject.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityIdentifier("quickadd.save")
                }
            }
        }
    }

    private func saveItem() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)

        if entryType == .assignment {
            let assignment = Assignment(
                title: cleanTitle,
                subject: cleanSubject,
                courseName: cleanSubject,
                dueDate: dueDate,
                estimatedMinutes: estimatedMinutes,
                priority: priority,
                notes: notes,
                source: .manual
            )
            AssignmentStore.shared.saveNew(assignment, in: modelContext)
        } else {
            let exam = ExamEvent(
                title: cleanTitle,
                subject: cleanSubject,
                date: dueDate,
                type: examType,
                notes: notes,
                preparationDays: preparationDays,
                priority: priority
            )
            modelContext.insert(exam)
            Task {
                try? await NotificationManager.shared.scheduleExamReminders(for: exam)
            }
        }

        try? modelContext.saveOrThrow()
        WidgetSnapshotWriter.reload(context: modelContext)
        dismiss()
    }
}
