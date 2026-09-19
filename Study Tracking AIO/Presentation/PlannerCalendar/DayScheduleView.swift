//
//  DayScheduleView.swift
//  StudyOS
//

import SwiftUI
import SwiftData

public struct DayScheduleView: View {
    @Environment(AppState.self) private var appState

    public let blocks: [PlannedStudyBlock]
    public let onRecalculate: () -> Void

    public init(blocks: [PlannedStudyBlock], onRecalculate: @escaping () -> Void) {
        self.blocks = blocks
        self.onRecalculate = onRecalculate
    }

    public var body: some View {
        if blocks.isEmpty {
            StudyOSEmptyState(
                title: "No Study Blocks Scheduled",
                systemImage: "calendar.badge.clock",
                description: "You have no active assignments or exams requiring study today.",
                actionTitle: "Recalculate Plan",
                action: onRecalculate
            )
        } else {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total Blocks")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(blocks.filter { !$0.isBreak }.count)")
                                .font(.headline)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Total Study Time")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            let totalMin = blocks.filter { !$0.isBreak }.reduce(0) { $0 + $1.durationMinutes }
                            Text("\(totalMin) min")
                                .font(.headline)
                        }
                    }
                    .padding(.vertical, 2)
                } header: {
                    Text("Today's Plan Summary")
                }

                Section {
                    ForEach(blocks) { block in
                        if block.isBreak {
                            HStack {
                                Image(systemName: "cup.and.saucer")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(block.title)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text("\(formattedTime(block.startTime)) – \(formattedTime(block.endTime)) • \(block.durationMinutes) min")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.vertical, 2)
                        } else {
                            HStack(alignment: .center, spacing: 12) {
                                VStack(alignment: .center, spacing: 2) {
                                    Text(formattedTime(block.startTime))
                                        .font(.caption.weight(.semibold))
                                    Text(formattedTime(block.endTime))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(minWidth: 60, alignment: .leading)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(block.title)
                                        .font(.body.weight(.medium))
                                    HStack {
                                        SubjectTag(subject: block.subject)
                                        Text("\(block.durationMinutes)m")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                Button {
                                    appState.startStudySession(durationMinutes: block.durationMinutes)
                                } label: {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.tint)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Start session for \(block.title)")
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    HStack {
                        Text("Deterministic Study Sequence")
                        Spacer()
                        Button("Recalculate", action: onRecalculate)
                            .font(.caption)
                    }
                } footer: {
                    Text("Calculated deterministically from assignment due dates, estimated effort, and exam prep windows. If you miss a block, tap Recalculate to reschedule remaining time without changing deadlines.")
                        .font(.caption2)
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private func formattedTime(_ date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
    }
}
