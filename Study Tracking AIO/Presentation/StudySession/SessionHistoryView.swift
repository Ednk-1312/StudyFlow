//
//  SessionHistoryView.swift
//  StudyOS
//

import SwiftUI
import SwiftData

public struct SessionHistoryView: View {
    @Query(sort: \StudySession.createdAt, order: .reverse) private var sessions: [StudySession]

    public init() {}

    private var totalMinutesStudied: Int {
        Int(sessions.reduce(0) { $0 + $1.actualDuration } / 60)
    }

    public var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Sessions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(sessions.count)")
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Total Time Logged")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(totalMinutesStudied) min")
                            .font(.headline)
                    }
                }
                .padding(.vertical, 2)
            } header: {
                Text("Study Activity")
            }

            Section("Past Sessions") {
                if sessions.isEmpty {
                    Text("No recorded study sessions yet. Start a session from the Home screen or any assignment.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sessions) { session in
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "timer")
                                .foregroundStyle(.tint)
                                .imageScale(.medium)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.subject)
                                    .font(.body.weight(.medium))
                                HStack(spacing: 6) {
                                    Text("\(Int(session.actualDuration / 60)) min focus")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if session.breaksDuration > 0 {
                                        Text("• \(Int(session.breaksDuration / 60)) min break")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                    if session.interruptionsCount > 0 {
                                        Text("• \(session.interruptionsCount) distractions")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }

                            Spacer()

                            if let comp = session.completedAt {
                                Text(DateFormatter.localizedString(from: comp, dateStyle: .short, timeStyle: .short))
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
        .navigationTitle("Session History")
        .navigationBarTitleDisplayMode(.inline)
    }
}
