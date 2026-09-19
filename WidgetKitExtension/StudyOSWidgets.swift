//
//  StudyOSWidgets.swift
//  StudyOSWidgets
//
//  StudyOS widgets. All data comes from WidgetSnapshot (real local app state
//  written by the app into the shared app group). Widgets never open the
//  SwiftData store directly — the app is the single writer, which keeps
//  store coordination simple and reliable.
//
//  Four widgets per the product spec:
//  1. Today's Assignments — remaining work for today
//  2. Next Assignment — the single most urgent item
//  3. Study Session — in-progress session indicator
//  4. Exam Countdown — days until the next exam/test
//

import WidgetKit
import SwiftUI

// MARK: - Timeline

/// WidgetKit asks the extension for a timeline of entries. The app refreshes
/// the snapshot at every meaningful change and calls WidgetCenter.reloadAll,
/// so the extension re-renders from the file; the timeline simply plans a
/// periodic re-render so relative dates ("in 2 hours") stay fresh.
struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

/// Reads the snapshot on the extension's process; tiny file, one read per
/// timeline request. WidgetKit calls this on background queues.
enum SnapshotReader {
    static func load() -> WidgetSnapshot? {
        WidgetSnapshot.load()
    }
}

struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: Date(), snapshot: SnapshotReader.load() ?? SnapshotProvider.sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(date: Date(), snapshot: SnapshotReader.load() ?? SnapshotProvider.sample))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        var entries = [SnapshotEntry(date: Date(), snapshot: SnapshotReader.load())]
        // Re-render a few times over the next day so "due in…" text stays honest.
        for hour in 1...6 {
            entries.append(SnapshotEntry(date: Calendar.current.date(byAdding: .hour, value: hour * 4, to: Date()) ?? Date(), snapshot: SnapshotReader.load()))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    /// Static preview used only when no snapshot exists yet (never shipped as
    /// user-facing data — real snapshots replace it the moment the app writes).
    static let sample = WidgetSnapshot(
        generatedAt: Date(),
        assignments: [
            AssignmentCard(id: UUID(), title: "Lab Questions", courseName: "Chemistry", dueDate: Date().addingTimeInterval(3600 * 20), estimatedMinutes: 25, isOverdue: false)
        ],
        nextExam: ExamCard(title: "Chapter Test", subject: "Chemistry", date: Date().addingTimeInterval(3600 * 24 * 4), typeName: "Chapter Test"),
        activeSession: nil
    )
}

// MARK: - Shared formatting

@main
struct StudyOSWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodaysAssignmentsWidget()
        NextAssignmentWidget()
        StudySessionWidget()
        ExamCountdownWidget()
    }
}

// MARK: - 1. Today's Assignments

struct TodaysAssignmentsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StudyOS.TodaysAssignments", provider: SnapshotProvider()) { entry in
            TodaysAssignmentsView(entry: entry)
        }
        .configurationDisplayName("Today's Assignments")
        .description("Assignments still to finish today.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct TodaysAssignmentsView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    private var todaysWork: [AssignmentCard] {
        guard let snapshot = entry.snapshot else { return [] }
        let calendar = Calendar.current
        return snapshot.assignments.filter { card in
            calendar.isDate(card.dueDate, inSameDayAs: entry.date) || card.dueDate < entry.date
        }
    }

    var body: some View {
        Group {
            if let snapshot = entry.snapshot, !todaysWork.isEmpty {
                content(items: todaysWork, remaining: snapshot.assignments.count)
            } else if entry.snapshot != nil {
                allClear
            } else {
                noData
            }
        }
        .widgetBackground()
    }

    private func content(items: [AssignmentCard], remaining: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("TODAY")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(items.count) left")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.tint)
            }
            ForEach(Array(items.prefix(family == .systemMedium ? 3 : 2).enumerated()), id: \.element.id) { _, card in
                VStack(alignment: .leading, spacing: 1) {
                    Text(card.courseName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(card.title)
                        .font(.footnote.weight(.medium))
                        .lineLimit(1)
                    if card.isOverdue {
                        Text("Overdue")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.red)
                    } else {
                        Text(card.dueDate, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var allClear: some View {
        VStack(spacing: 4) {
            Image(systemName: "checkmark.circle")
                .font(.title3)
                .foregroundStyle(.tint)
            Text("All caught up")
                .font(.footnote.weight(.medium))
            Text("Nothing due today")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noData: some View {
        VStack(spacing: 4) {
            Image(systemName: "checklist")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("No assignments yet")
                .font(.footnote.weight(.medium))
            Text("Open StudyOS to add one")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 2. Next Assignment

struct NextAssignmentWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StudyOS.NextAssignment", provider: SnapshotProvider()) { entry in
            NextAssignmentView(entry: entry)
        }
        .configurationDisplayName("Next Assignment")
        .description("The assignment due soonest.")
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryInline])
    }
}

struct NextAssignmentView: View {
    let entry: SnapshotEntry

    private var next: AssignmentCard? {
        entry.snapshot?.assignments.min { $0.dueDate < $1.dueDate }
    }

    var body: some View {
        Group {
            if entry.snapshot == nil {
                VStack(spacing: 4) {
                    Image(systemName: "checklist")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Open StudyOS to add your first assignment")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else if let next {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(next.courseName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(next.title)
                        .font(.footnote.weight(.semibold))
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    if next.isOverdue {
                        Text("Overdue")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.red)
                    } else {
                        Text(next.dueDate, style: .relative)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.tint)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.title3)
                        .foregroundStyle(.tint)
                    Text("All caught up")
                        .font(.footnote.weight(.medium))
                }
            }
        }
        .widgetBackground()
    }
}

// MARK: - 3. Study Session

struct StudySessionWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StudyOS.StudySession", provider: SnapshotProvider()) { entry in
            StudySessionView(entry: entry)
        }
        .configurationDisplayName("Study Session")
        .description("Shows the session currently running in StudyOS.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

struct StudySessionView: View {
    let entry: SnapshotEntry

    var body: some View {
        Group {
            if entry.snapshot == nil {
                emptyView(icon: "timer", title: "Open StudyOS", detail: "Start a session from the app")
            } else if let session = entry.snapshot?.activeSession {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.tint)
                            .frame(width: 7, height: 7)
                        Text("STUDYING")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tint)
                    }
                    Text(session.assignmentTitle ?? "Focus session")
                        .font(.footnote.weight(.semibold))
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    Text("\(session.plannedMinutes) min planned")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                emptyView(icon: "timer", title: "No session running", detail: "Start one in StudyOS")
            }
        }
        .widgetBackground()
    }

    private func emptyView(icon: String, title: String, detail: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.footnote.weight(.medium))
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 4. Exam Countdown

struct ExamCountdownWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StudyOS.ExamCountdown", provider: SnapshotProvider()) { entry in
            ExamCountdownView(entry: entry)
        }
        .configurationDisplayName("Exam Countdown")
        .description("Days until your next exam or test.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

struct ExamCountdownView: View {
    let entry: SnapshotEntry

    private var daysRemaining: Int? {
        guard let exam = entry.snapshot?.nextExam else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: entry.date), to: Calendar.current.startOfDay(for: exam.date)).day
        return max(0, days ?? 0)
    }

    var body: some View {
        Group {
            if entry.snapshot == nil {
                VStack(spacing: 4) {
                    Image(systemName: "graduationcap")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Open StudyOS to add an exam")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else if let exam = entry.snapshot?.nextExam, let days = daysRemaining {
                VStack(alignment: .leading, spacing: 3) {
                    Text(exam.typeName.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(days)")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.tint)
                        .minimumScaleFactor(0.5)
                    Text(days == 1 ? "day until \(exam.subject) \(exam.title)" : "days until \(exam.subject) \(exam.title)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "graduationcap")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("No exams scheduled")
                        .font(.footnote.weight(.medium))
                }
            }
        }
        .widgetBackground()
    }
}

// MARK: - Background handling

/// iOS 17+ requires an explicit background; margins are handled by the system.
extension View {
    func widgetBackground() -> some View {
        containerBackground(for: .widget) { Color.clear }
    }
}
