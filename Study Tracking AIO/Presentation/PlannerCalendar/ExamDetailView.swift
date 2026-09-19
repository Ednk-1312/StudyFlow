//
//  ExamDetailView.swift
//  StudyOS
//

import SwiftUI
import SwiftData

public struct ExamDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    public let exam: ExamEvent

    @State private var isDeleteConfirmationPresented: Bool = false

    public init(exam: ExamEvent) {
        self.exam = exam
    }

    private var daysUntilExam: Int {
        let diff = Calendar.current.dateComponents([.day], from: Date(), to: exam.date).day ?? 0
        return max(0, diff)
    }

    public var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        SubjectTag(subject: exam.subject)
                        Spacer()
                        PriorityBadge(priority: exam.priority)
                    }

                    Text(exam.title)
                        .font(.title2.weight(.bold))

                    HStack(spacing: 8) {
                        Image(systemName: exam.type.systemImage)
                            .foregroundStyle(.tint)
                        Text(exam.type.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(daysUntilExam) days remaining")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(daysUntilExam <= 2 ? .red : .primary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Exam Schedule") {
                HStack {
                    Label("Exam Date & Time", systemImage: "calendar")
                    Spacer()
                    Text(DateFormatter.localizedString(from: exam.date, dateStyle: .full, timeStyle: .short))
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Prep Window", systemImage: "hourglass")
                    Spacer()
                    Text("\(exam.preparationDays) days before exam")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Prep Begins", systemImage: "calendar.badge.clock")
                    Spacer()
                    Text(DateFormatter.localizedString(from: exam.preparationStartDate, dateStyle: .medium, timeStyle: .none))
                        .foregroundStyle(.secondary)
                }
            }

            if !exam.notes.isEmpty {
                Section("Topics & Study Notes") {
                    Text(exam.notes)
                        .font(.body)
                }
            }

            Section {
                Button(role: .destructive) {
                    isDeleteConfirmationPresented = true
                } label: {
                    Label("Delete Exam", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Exam Details")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete Exam?", isPresented: $isDeleteConfirmationPresented, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                let id = exam.id
                Task {
                    await NotificationManager.shared.cancelExamReminders(for: id)
                }
                modelContext.delete(exam)
                try? modelContext.saveOrThrow()
                WidgetSnapshotWriter.reload(context: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
