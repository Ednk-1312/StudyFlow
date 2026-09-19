//
//  PlannerCalendarView.swift
//  StudyOS
//

import SwiftUI
import SwiftData

public struct PlannerCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query(sort: \Assignment.dueDate, order: .forward) private var assignments: [Assignment]
    @Query(sort: \ExamEvent.date, order: .forward) private var exams: [ExamEvent]

    @State private var viewMode: PlannerMode = .dayPlan
    @State private var selectedDate: Date = Date()
    @State private var generatedBlocks: [PlannedStudyBlock] = []
    @State private var isQuickAddPresented: Bool = false

    public enum PlannerMode: String, CaseIterable {
        case dayPlan = "Day Schedule"
        case calendar = "School Calendar"
    }

    public init() {}

    private var selectedDayAssignments: [Assignment] {
        let cal = Calendar.current
        return assignments.filter { cal.isDate($0.dueDate, inSameDayAs: selectedDate) }
    }

    private var selectedDayExams: [ExamEvent] {
        let cal = Calendar.current
        return exams.filter { cal.isDate($0.date, inSameDayAs: selectedDate) || ($0.isInsidePreparationWindow && cal.isDate($0.preparationStartDate, inSameDayAs: selectedDate)) }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View Mode", selection: $viewMode) {
                    ForEach(PlannerMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                if viewMode == .dayPlan {
                    DayScheduleView(blocks: generatedBlocks) {
                        recalculatePlan()
                    }
                } else {
                    calendarView
                }
            }
            .navigationTitle("Planner & Calendar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isQuickAddPresented = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isQuickAddPresented) {
                QuickAddSheet()
            }
            .onAppear {
                if generatedBlocks.isEmpty {
                    recalculatePlan()
                }
            }
            .onChange(of: assignments.count) { _, _ in
                recalculatePlan()
            }
            .onChange(of: exams.count) { _, _ in
                recalculatePlan()
            }
        }
    }

    private var calendarView: some View {
        List {
            Section {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding(.vertical, 4)
            }

            Section("Events on \(formattedSelectedDate())") {
                if selectedDayAssignments.isEmpty && selectedDayExams.isEmpty {
                    Text("No assignments or exams on this date.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(selectedDayExams) { exam in
                        NavigationLink(destination: ExamDetailView(exam: exam)) {
                            HStack {
                                Image(systemName: exam.type.systemImage)
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exam.title)
                                        .font(.body.weight(.medium))
                                    Text("\(exam.subject) • \(exam.type.rawValue)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("Exam")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }

                    ForEach(selectedDayAssignments) { assignment in
                        NavigationLink(destination: AssignmentDetailView(assignment: assignment)) {
                            AssignmentRowView(assignment: assignment)
                        }
                    }
                }
            }

            Section("All Upcoming Exams & Prep Windows (\(exams.count))") {
                if exams.isEmpty {
                    Text("No exams recorded. Tap + to add an exam date.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(exams) { exam in
                        NavigationLink(destination: ExamDetailView(exam: exam)) {
                            HStack {
                                Image(systemName: exam.type.systemImage)
                                    .foregroundStyle(.tint)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exam.title)
                                        .font(.body.weight(.medium))
                                    Text("\(exam.subject) • Prep window: \(exam.preparationDays) days")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(DateFormatter.localizedString(from: exam.date, dateStyle: .short, timeStyle: .none))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func formattedSelectedDate() -> String {
        DateFormatter.localizedString(from: selectedDate, dateStyle: .medium, timeStyle: .none)
    }

    private func recalculatePlan() {
        generatedBlocks = DeterministicStudyPlanner.shared.generateDailyPlan(
            assignments: assignments,
            exams: exams,
            startDate: Date()
        )
    }
}
