//
//  AssignmentListView.swift
//  StudyOS
//

import SwiftUI
import SwiftData

public struct AssignmentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query(sort: \Assignment.dueDate, order: .forward) private var assignments: [Assignment]

    @State private var filterSegment: AssignmentFilter = .active
    @State private var selectedSubject: String? = nil
    @State private var searchText: String = ""
    @State private var isAddSheetPresented: Bool = false
    @State private var isScanSheetPresented: Bool = false

    public enum AssignmentFilter: String, CaseIterable {
        case active = "Active"
        case today = "Today"
        case upcoming = "Upcoming"
        case completed = "Done"
        case all = "All"
    }

    public init() {}

    private var availableSubjects: [String] {
        Array(Set(assignments.map(\.courseName))).sorted()
    }

    private var filteredAssignments: [Assignment] {
        let calendar = Calendar.current
        let now = Date()

        return assignments.filter { assignment in
            // Search text filter
            if !searchText.isEmpty {
                let matchesTitle = assignment.title.localizedCaseInsensitiveContains(searchText)
                let matchesSubject = assignment.courseName.localizedCaseInsensitiveContains(searchText)
                let matchesNotes = assignment.notes.localizedCaseInsensitiveContains(searchText)
                if !matchesTitle && !matchesSubject && !matchesNotes {
                    return false
                }
            }

            // Subject filter
            if let subject = selectedSubject, assignment.courseName != subject {
                return false
            }

            // Status / Segment filter
            switch filterSegment {
            case .active:
                return assignment.status != .completed
            case .today:
                return calendar.isDateInToday(assignment.dueDate) && assignment.status != .completed
            case .upcoming:
                return assignment.dueDate > now && !calendar.isDateInToday(assignment.dueDate) && assignment.status != .completed
            case .completed:
                return assignment.status == .completed
            case .all:
                return true
            }
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Filter", selection: $filterSegment) {
                    ForEach(AssignmentFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("assignments.filter")
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                if filteredAssignments.isEmpty {
                    StudyOSEmptyState(
                        title: emptyStateTitle,
                        systemImage: "checklist",
                        description: emptyStateDescription,
                        actionTitle: "Add Assignment",
                        action: { isAddSheetPresented = true }
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredAssignments) { assignment in
                            NavigationLink(destination: AssignmentDetailView(assignment: assignment)) {
                                AssignmentRowView(assignment: assignment)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    toggleCompletion(for: assignment)
                                } label: {
                                    Label(
                                        assignment.status == .completed ? "Incomplete" : "Complete",
                                        systemImage: assignment.status == .completed ? "arrow.uturn.backward" : "checkmark"
                                    )
                                }
                                .tint(assignment.status == .completed ? .secondary : .green)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteAssignment(assignment)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button {
                                    appState.startStudySession(for: assignment, durationMinutes: min(assignment.estimatedMinutes, 30))
                                } label: {
                                    Label("Start Study Session", systemImage: "play.fill")
                                }

                                Button {
                                    toggleCompletion(for: assignment)
                                } label: {
                                    Label(assignment.status == .completed ? "Mark Incomplete" : "Mark Complete", systemImage: "checkmark")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Assignments")
            .searchable(text: $searchText, prompt: "Search title, class, or notes")
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("All Classes") {
                            selectedSubject = nil
                        }
                        Divider()
                        ForEach(availableSubjects, id: \.self) { subject in
                            Button(subject) {
                                selectedSubject = subject
                            }
                        }
                    } label: {
                        Label(
                            selectedSubject ?? "Filter Class",
                            systemImage: selectedSubject == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill"
                        )
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        isScanSheetPresented = true
                    } label: {
                        Label("Scan Document", systemImage: "doc.viewfinder")
                    }

                    Button {
                        isAddSheetPresented = true
                    } label: {
                        Label("Add Assignment", systemImage: "plus")
                    }
                    .accessibilityIdentifier("assignments.add")
                }
            }
            .sheet(isPresented: $isAddSheetPresented) {
                AssignmentEditView()
            }
            .sheet(isPresented: $isScanSheetPresented) {
                ScanAssignmentView()
            }
        }
    }

    private var emptyStateTitle: String {
        switch filterSegment {
        case .active: return "No active assignments"
        case .today: return "No assignments due today"
        case .upcoming: return "No upcoming assignments"
        case .completed: return "No completed assignments"
        case .all: return "No assignments found"
        }
    }

    private var emptyStateDescription: String {
        if let subject = selectedSubject {
            return "No assignments found for \(subject). You can add an assignment manually or scan a worksheet."
        }
        switch filterSegment {
        case .active: return "You have no outstanding school tasks. Add your next assignment or scan a syllabus."
        case .today: return "Nothing scheduled for today. Check upcoming days or relax."
        case .upcoming: return "All upcoming assignments have been completed or none are scheduled yet."
        case .completed: return "Assignments you complete will be archived here."
        case .all: return "Get started by adding your first school assignment or importing from Google Classroom."
        }
    }

    private func toggleCompletion(for assignment: Assignment) {
        let undo = AssignmentStore.shared.toggleCompletion(of: assignment, in: modelContext)
        Haptics.success()
        appState.showUndoToast(message: assignment.status == .completed ? "Completed \"\(assignment.title)\"" : "Marked incomplete") {
            undo()
        }
    }

    private func deleteAssignment(_ assignment: Assignment) {
        let title = assignment.title
        let undo = AssignmentStore.shared.delete(assignment, in: modelContext)
        Haptics.warning()
        appState.showUndoToast(message: "Deleted \"\(title)\"") {
            undo()
        }
    }
}
