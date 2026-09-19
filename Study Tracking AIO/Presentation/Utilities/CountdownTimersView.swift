//
//  CountdownTimersView.swift
//  StudyOS
//

import SwiftUI
import SwiftData

public struct CountdownTimersView: View {
    @Query(sort: \ExamEvent.date, order: .forward) private var exams: [ExamEvent]
    @Query(sort: \Assignment.dueDate, order: .forward) private var assignments: [Assignment]

    public init() {}

    private var activeAssignments: [Assignment] {
        assignments.filter { $0.status != .completed }
    }

    public var body: some View {
        List {
            Section("Upcoming Exams") {
                if exams.isEmpty {
                    Text("No upcoming exams recorded.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(exams) { exam in
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: exam.type.systemImage)
                                .font(.title3)
                                .foregroundStyle(.orange)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(exam.title)
                                    .font(.body.weight(.medium))
                                Text(exam.subject)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(countdownText(to: exam.date))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(exam.date < Date() ? .red : .primary)
                                Text(DateFormatter.localizedString(from: exam.date, dateStyle: .short, timeStyle: .none))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Section("Upcoming Assignment Deadlines") {
                if activeAssignments.isEmpty {
                    Text("No active assignments.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(activeAssignments) { assignment in
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "clock")
                                .foregroundStyle(.tint)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(assignment.title)
                                    .font(.body.weight(.medium))
                                Text(assignment.courseName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(countdownText(to: assignment.dueDate))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(assignment.status == .overdue ? .red : .primary)
                                Text(DateFormatter.localizedString(from: assignment.dueDate, dateStyle: .short, timeStyle: .short))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Deadlines Countdown")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func countdownText(to targetDate: Date) -> String {
        let diff = Calendar.current.dateComponents([.day, .hour, .minute], from: Date(), to: targetDate)
        let days = diff.day ?? 0
        let hours = diff.hour ?? 0
        let minutes = diff.minute ?? 0

        if targetDate < Date() {
            return "Overdue"
        }

        if days > 0 {
            return "\(days)d \(hours)h left"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m left"
        } else {
            return "\(max(1, minutes))m left"
        }
    }
}
