//
//  HomeView.swift
//  StudyOS
//

import SwiftUI
import SwiftData

public struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query(sort: \Assignment.dueDate, order: .forward) private var allAssignments: [Assignment]
    @Query(sort: \ExamEvent.date, order: .forward) private var allExams: [ExamEvent]
    @Query(sort: \StudySession.createdAt, order: .reverse) private var recentSessions: [StudySession]

    private let syncEngine = SyncEngine.shared

    public init() {}

    private var activeAssignments: [Assignment] {
        allAssignments.filter { $0.status != .completed }
    }

    private var recommendedNextAssignment: Assignment? {
        DeterministicStudyPlanner.shared.prioritizeAssignments(allAssignments, asOf: Date()).first
    }

    private var todaysAssignments: [Assignment] {
        let calendar = Calendar.current
        return activeAssignments.filter { calendar.isDateInToday($0.dueDate) }
    }

    private var upcomingExamsInPrepWindow: [ExamEvent] {
        allExams.filter { $0.isInsidePreparationWindow }
    }

    private var totalEstimatedMinutesRemaining: Int {
        activeAssignments.reduce(0) { $0 + $1.estimatedMinutes }
    }

    public var body: some View {
        @Bindable var state = appState

        return NavigationStack {
            List {
                // Sync status banner only when Classroom is connected and something needs attention
                if GoogleClassroomService.shared.isConnected,
                   !syncEngine.isSyncing,
                   case .success = syncEngine.syncStatus {
                    // Quiet after a successful sync; no banner needed.
                } else if GoogleClassroomService.shared.isConnected {
                    Section {
                        HStack(spacing: 8) {
                            if syncEngine.syncStatus.isSyncing {
                                ProgressView()
                            } else {
                                Image(systemName: syncEngine.syncStatus.systemImage)
                                    .foregroundStyle(.secondary)
                            }
                            Text(syncEngine.syncStatus.displayMessage)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // 1. Recommended Next Action & Primary CTA
                Section("Recommended Next Action") {
                    if let nextTask = recommendedNextAssignment {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                SubjectTag(subject: nextTask.courseName)
                                Spacer()
                                PriorityBadge(priority: nextTask.priority)
                            }

                            Text(nextTask.title)
                                .font(.headline)

                            HStack {
                                Label("Due \(formattedDueDate(nextTask.dueDate))", systemImage: "clock")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("~ \(nextTask.estimatedMinutes)m effort")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Button {
                                appState.startStudySession(for: nextTask, durationMinutes: min(nextTask.estimatedMinutes, 30))
                            } label: {
                                Label("Start Study Session", systemImage: "play.fill")
                                    .font(.body.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("home.startSession")
                            .controlSize(.large)
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 4)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("All caught up")
                                .font(.headline)
                            Text("No pending assignments on your schedule. You can add one manually or scan a worksheet.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // 2. Today's Work Summary
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Active Tasks")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(activeAssignments.count)")
                                .font(.title3.weight(.bold))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Work Remaining")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(formattedMinutes(totalEstimatedMinutesRemaining))
                                .font(.title3.weight(.bold))
                        }
                    }
                    .padding(.vertical, 2)
                } header: {
                    Text("Workload Overview")
                }

                // 3. Due Today
                if !todaysAssignments.isEmpty {
                    Section("Due Today (\(todaysAssignments.count))") {
                        ForEach(todaysAssignments) { assignment in
                            NavigationLink(destination: AssignmentDetailView(assignment: assignment)) {
                                AssignmentRowView(assignment: assignment)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    toggleCompletion(for: assignment)
                                } label: {
                                    Label("Complete", systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                        }
                    }
                }

                // 4. Upcoming Exams in Prep Window
                if !upcomingExamsInPrepWindow.isEmpty {
                    Section("Upcoming Exams in Prep Window") {
                        ForEach(upcomingExamsInPrepWindow) { exam in
                            HStack {
                                Image(systemName: exam.type.systemImage)
                                    .foregroundStyle(.tint)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exam.title)
                                        .font(.body.weight(.medium))
                                    Text("\(exam.subject) • \(daysUntil(exam.date)) days away")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(DateFormatter.localizedString(from: exam.date, dateStyle: .short, timeStyle: .none))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                // 5. Recent Study Activity
                if let lastSession = recentSessions.first(where: { $0.status == .completed }) {
                    Section("Last Study Session") {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundStyle(.tint)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lastSession.subject)
                                    .font(.body.weight(.medium))
                                Text("Studied \(Int(lastSession.actualDuration / 60)) minutes")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let comp = lastSession.completedAt {
                                Text(DateFormatter.localizedString(from: comp, dateStyle: .short, timeStyle: .short))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(todayFormattedTitle())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        appState.isScanPresented = true
                    } label: {
                        Label("Scan", systemImage: "doc.viewfinder")
                    }
                    .accessibilityIdentifier("home.scan")
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        appState.isQuickAddPresented = true
                    } label: {
                        Label("Add Task", systemImage: "plus")
                    }
                    .accessibilityIdentifier("home.addTask")
                    Button {
                        appState.isSettingsPresented = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .accessibilityIdentifier("home.settings")
                }
            }
            .sheet(isPresented: $state.isQuickAddPresented) {
                QuickAddSheet()
            }
            .sheet(isPresented: $state.isScanPresented) {
                ScanAssignmentView()
            }
        }
    }

    private static let titleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()

    private func todayFormattedTitle() -> String {
        Self.titleFormatter.string(from: Date())
    }

    private func formattedDueDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today at \(DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short))"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            return DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
        }
    }

    private func formattedMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let h = minutes / 60
            let m = minutes % 60
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
    }

    private func daysUntil(_ date: Date) -> Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return max(0, days)
    }

    private func toggleCompletion(for assignment: Assignment) {
        let undo = AssignmentStore.shared.toggleCompletion(of: assignment, in: modelContext)
        Haptics.success()
        appState.showUndoToast(message: "Completed \"\(assignment.title)\"") {
            undo()
        }
    }
}

public struct AssignmentRowView: View {
    public let assignment: Assignment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(assignment: Assignment) {
        self.assignment = assignment
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Completion state animates so the change reads clearly;
            // skipped under Reduce Motion.
            Image(systemName: assignment.status == .completed ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(assignment.status == .completed ? .green : .secondary)
                .imageScale(.large)
                .scaleEffect(assignment.status == .completed && !reduceMotion ? 1.15 : 1)
                .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6), value: assignment.status)

            VStack(alignment: .leading, spacing: 3) {
                Text(assignment.title)
                    .font(.body.weight(.medium))
                    .strikethrough(assignment.status == .completed, color: .secondary)

                HStack(spacing: 6) {
                    SubjectTag(subject: assignment.courseName)
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text(DateFormatter.localizedString(from: assignment.dueDate, dateStyle: .short, timeStyle: .short))
                        .font(.caption)
                        .foregroundStyle(assignment.status == .overdue ? .red : .secondary)
                }
            }

            Spacer()

            PriorityBadge(priority: assignment.priority)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(assignment.title), \(assignment.courseName), \(statusPhrase), Priority: \(assignment.priority.rawValue), Due \(DateFormatter.localizedString(from: assignment.dueDate, dateStyle: .short, timeStyle: .short))")
    }

    private var statusPhrase: String {
        switch assignment.status {
        case .completed: return "Completed"
        case .overdue: return "Overdue"
        case .inProgress: return "In progress"
        default: return String()
        }
    }
}
