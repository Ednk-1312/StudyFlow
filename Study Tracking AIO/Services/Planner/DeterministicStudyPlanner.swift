//
//  DeterministicStudyPlanner.swift
//  StudyOS
//

import Foundation

public struct PlannedStudyBlock: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let assignmentID: UUID?
    public let examID: UUID?
    public let title: String
    public let subject: String
    public let startTime: Date
    public let durationMinutes: Int
    public let isBreak: Bool
    public let notes: String

    public var endTime: Date {
        startTime.addingTimeInterval(Double(durationMinutes) * 60.0)
    }

    public init(
        id: UUID = UUID(),
        assignmentID: UUID? = nil,
        examID: UUID? = nil,
        title: String,
        subject: String,
        startTime: Date,
        durationMinutes: Int,
        isBreak: Bool = false,
        notes: String = ""
    ) {
        self.id = id
        self.assignmentID = assignmentID
        self.examID = examID
        self.title = title
        self.subject = subject
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.isBreak = isBreak
        self.notes = notes
    }
}

public struct PlannerConfiguration: Equatable, Sendable {
    public var preferredBlockMinutes: Int
    public var shortBreakMinutes: Int
    public var dailyStudyMinutesLimit: Int
    public var dayStartTimeHours: Int // e.g. 16 for 4:00 PM
    public var dayStartTimeMinutes: Int

    public init(
        preferredBlockMinutes: Int = 30,
        shortBreakMinutes: Int = 5,
        dailyStudyMinutesLimit: Int = 180,
        dayStartTimeHours: Int = 16,
        dayStartTimeMinutes: Int = 0
    ) {
        self.preferredBlockMinutes = max(15, preferredBlockMinutes)
        self.shortBreakMinutes = max(3, shortBreakMinutes)
        self.dailyStudyMinutesLimit = max(30, dailyStudyMinutesLimit)
        self.dayStartTimeHours = dayStartTimeHours
        self.dayStartTimeMinutes = dayStartTimeMinutes
    }
}

public final class DeterministicStudyPlanner: Sendable {
    public static let shared = DeterministicStudyPlanner()

    public init() {}

    // MARK: - Task Ordering Algorithm

    public struct ScoredTask: Equatable {
        public let assignment: Assignment
        public let score: Double
    }

    /// Sorts assignments deterministically by calculated urgency and priority.
    /// Formula: (priorityWeight * 1000.0) / max(0.5, sqrt(hoursUntilDue))
    public func prioritizeAssignments(
        _ assignments: [Assignment],
        asOf referenceDate: Date = Date()
    ) -> [Assignment] {
        let active = assignments.filter { $0.status != .completed }

        let scored = active.map { assignment -> (Assignment, Double) in
            let hoursUntilDue = max(0.5, assignment.dueDate.timeIntervalSince(referenceDate) / 3600.0)
            let priorityWeight: Double
            switch assignment.priority {
            case .urgent: priorityWeight = 4.0
            case .high: priorityWeight = 3.0
            case .medium: priorityWeight = 2.0
            case .low: priorityWeight = 1.0
            }

            // Overdue tasks receive maximum urgency multiplier
            let overdueMultiplier = assignment.dueDate < referenceDate ? 5.0 : 1.0
            let score = (priorityWeight * 1000.0 * overdueMultiplier) / sqrt(hoursUntilDue)
            return (assignment, score)
        }

        return scored.sorted { first, second in
            if abs(first.1 - second.1) > 0.001 {
                return first.1 > second.1
            }
            // Tie-breaker: earlier due date
            if first.0.dueDate != second.0.dueDate {
                return first.0.dueDate < second.0.dueDate
            }
            // Tie-breaker: alphabetical title
            return first.0.title < second.0.title
        }.map(\.0)
    }

    // MARK: - Plan Generation

    public func generateDailyPlan(
        assignments: [Assignment],
        exams: [ExamEvent],
        startDate: Date = Date(),
        config: PlannerConfiguration = PlannerConfiguration()
    ) -> [PlannedStudyBlock] {
        var blocks: [PlannedStudyBlock] = []

        // Set initial block start time for the day
        let calendar = Calendar.current
        var currentBlockStart: Date
        let components = calendar.dateComponents([.year, .month, .day], from: startDate)
        var targetComponents = components
        targetComponents.hour = config.dayStartTimeHours
        targetComponents.minute = config.dayStartTimeMinutes
        let configuredStart = calendar.date(from: targetComponents) ?? startDate

        if startDate > configuredStart {
            // If current time is past preferred day start, start at next 5-minute round mark
            let nextFiveMin = ceil(startDate.timeIntervalSinceReferenceDate / 300.0) * 300.0
            currentBlockStart = Date(timeIntervalSinceReferenceDate: nextFiveMin)
        } else {
            currentBlockStart = configuredStart
        }

        var remainingDailyMinutes = config.dailyStudyMinutesLimit

        // 1. First allocate preparation blocks for active exams inside their prep window
        let activeExams = exams.filter { $0.isInsidePreparationWindow }.sorted { $0.date < $1.date }
        for exam in activeExams {
            guard remainingDailyMinutes >= config.preferredBlockMinutes else { break }

            let examBlockMinutes = min(config.preferredBlockMinutes, remainingDailyMinutes)
            let block = PlannedStudyBlock(
                examID: exam.id,
                title: "Prep: \(exam.title)",
                subject: exam.subject,
                startTime: currentBlockStart,
                durationMinutes: examBlockMinutes,
                notes: "Review exam notes and practice problems. Exam is on \(DateFormatter.localizedString(from: exam.date, dateStyle: .short, timeStyle: .none))."
            )
            blocks.append(block)
            currentBlockStart = block.endTime
            remainingDailyMinutes -= examBlockMinutes

            // Add short break
            if remainingDailyMinutes > config.shortBreakMinutes {
                let breakBlock = PlannedStudyBlock(
                    title: "Rest Break",
                    subject: "Break",
                    startTime: currentBlockStart,
                    durationMinutes: config.shortBreakMinutes,
                    isBreak: true,
                    notes: "Step away from screen, hydrate, stretch."
                )
                blocks.append(breakBlock)
                currentBlockStart = breakBlock.endTime
            }
        }

        // 2. Allocate prioritized assignments
        let prioritized = prioritizeAssignments(assignments, asOf: startDate)

        for assignment in prioritized {
            guard remainingDailyMinutes >= 15 else { break }

            var taskMinutesRemaining = assignment.estimatedMinutes

            while taskMinutesRemaining > 0 && remainingDailyMinutes >= 15 {
                let blockDuration = min(config.preferredBlockMinutes, taskMinutesRemaining, remainingDailyMinutes)

                let block = PlannedStudyBlock(
                    assignmentID: assignment.id,
                    title: assignment.title,
                    subject: assignment.courseName,
                    startTime: currentBlockStart,
                    durationMinutes: blockDuration,
                    notes: assignment.notes.isEmpty ? "Focus session for \(assignment.title)." : assignment.notes
                )
                blocks.append(block)
                currentBlockStart = block.endTime
                taskMinutesRemaining -= blockDuration
                remainingDailyMinutes -= blockDuration

                // Add short break if more time remains in study budget
                if remainingDailyMinutes > config.shortBreakMinutes && (taskMinutesRemaining > 0 || remainingDailyMinutes >= 20) {
                    let breakBlock = PlannedStudyBlock(
                        title: "Short Break",
                        subject: "Break",
                        startTime: currentBlockStart,
                        durationMinutes: config.shortBreakMinutes,
                        isBreak: true,
                        notes: "Rest your eyes for 5 minutes."
                    )
                    blocks.append(breakBlock)
                    currentBlockStart = breakBlock.endTime
                }
            }
        }

        return blocks
    }

    // MARK: - Dynamic Recalculation

    /// Recalculates remaining blocks when a user doesn't finish or completes early,
    /// without ever altering the official assignment due dates.
    public func recalculateSchedule(
        existingPlan: [PlannedStudyBlock],
        completedBlockIDs: Set<UUID>,
        unfinishedAssignments: [Assignment],
        exams: [ExamEvent],
        from newReferenceDate: Date,
        config: PlannerConfiguration = PlannerConfiguration()
    ) -> [PlannedStudyBlock] {
        // Retain past completed blocks
        let completedPastBlocks = existingPlan.filter { completedBlockIDs.contains($0.id) }

        // Generate fresh future plan for remaining tasks starting at newReferenceDate
        let futurePlan = generateDailyPlan(
            assignments: unfinishedAssignments,
            exams: exams,
            startDate: newReferenceDate,
            config: config
        )

        return completedPastBlocks + futurePlan
    }
}
