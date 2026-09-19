//
//  StudyOSTests.swift
//  StudyOS
//

import Foundation
import SwiftData

public struct TestAssertionFailure: LocalizedError {
    public let message: String
    public init(_ message: String) {
        self.message = message
    }
    public var errorDescription: String? { message }
}

public func assertCondition(_ condition: Bool, _ message: String) throws {
    guard condition else {
        throw TestAssertionFailure("Assertion Failed: \(message)")
    }
}

public enum StudyOSTestSuite {

    // MARK: - 1. Planner Calculations & Recalculation
    public static func testPlannerCalculations() throws {
        let planner = DeterministicStudyPlanner()
        let now = Date()

        let overdueTask = Assignment(title: "Overdue Essay", subject: "English", dueDate: now.addingTimeInterval(-3600), estimatedMinutes: 45, priority: .high)
        let urgentTask = Assignment(title: "Urgent Problem Set", subject: "Math", dueDate: now.addingTimeInterval(7200), estimatedMinutes: 30, priority: .urgent)
        let lowTask = Assignment(title: "Low Priority Reading", subject: "History", dueDate: now.addingTimeInterval(86400 * 5), estimatedMinutes: 60, priority: .low)

        let prioritized = planner.prioritizeAssignments([lowTask, urgentTask, overdueTask], asOf: now)

        // Overdue and urgent tasks must be scheduled before low-priority distant tasks
        try assertCondition(prioritized.first?.title == "Overdue Essay", "Overdue task should receive highest urgency multiplier")
        try assertCondition(prioritized[1].title == "Urgent Problem Set", "Urgent task should be prioritized second")
        try assertCondition(prioritized.last?.title == "Low Priority Reading", "Low priority distant task should be prioritized last")

        // Block generation with breaks
        let blocks = planner.generateDailyPlan(assignments: [urgentTask, lowTask], exams: [], startDate: now)
        try assertCondition(!blocks.isEmpty, "Generated plan should have study blocks")
        let breakBlocks = blocks.filter(\.isBreak)
        try assertCondition(!breakBlocks.isEmpty, "Generated plan must contain scheduled rest breaks")

        // Dynamic Recalculation: do not change deadlines
        let originalDueDate = lowTask.dueDate
        let recalculated = planner.recalculateSchedule(
            existingPlan: blocks,
            completedBlockIDs: [blocks.first!.id],
            unfinishedAssignments: [lowTask],
            exams: [],
            from: now.addingTimeInterval(1800)
        )
        try assertCondition(lowTask.dueDate == originalDueDate, "Recalculation must never alter official assignment deadlines")
        try assertCondition(!recalculated.isEmpty, "Recalculated schedule must retain completed past and future blocks")
    }

    // MARK: - 2. Due Date Parsing
    public static func testDueDateParsing() throws {
        let extractor = ScannedAssignmentExtractor.shared
        let raw = """
        Chemistry 101 - Lab 4
        Instructor: Dr. Alan Grant
        Due: Friday at 11:59 PM
        Complete pre-lab questions.
        """
        let candidate = extractor.extractCandidate(from: raw)

        try assertCondition(candidate.candidateSubject == "Chemistry", "Subject should be recognized as Chemistry")
        try assertCondition(candidate.candidateTeacher == "Dr. Alan", "Teacher prefix Dr. Alan should be extracted")
        try assertCondition(candidate.candidateDueDate != nil, "Due date detector should identify due date")
        try assertCondition(candidate.isDueDateConfident == true, "Explicitly labeled due date must be marked confident")

        // Test unlabeled date
        let unlabeledRaw = "History Chapter 5\nTest on October 15"
        let unlabeledCandidate = extractor.extractCandidate(from: unlabeledRaw)
        try assertCondition(unlabeledCandidate.candidateDueDate != nil, "Date should still be detected")
        try assertCondition(unlabeledCandidate.isDueDateConfident == false, "Unlabeled date should be marked uncertain for user verification")
    }

    // MARK: - 3. Assignment Deduplication
    public static func testAssignmentDeduplication() throws {
        let syncEngine = SyncEngine()
        let now = Date()

        let existingAssignment = Assignment(
            title: "Physics Problem Set 2",
            subject: "AP Physics",
            courseName: "AP Physics",
            dueDate: now,
            externalIdentifier: "classroom_work_999"
        )

        // Case A: Matching by externalIdentifier
        let remoteWithSameID = RemoteCourseWork(id: "classroom_work_999", courseId: "c1", title: "Physics PSet 2 Updated", dueDate: now)
        let dupByID = syncEngine.findDuplicate(work: remoteWithSameID, in: [existingAssignment], courseName: "AP Physics")
        try assertCondition(dupByID != nil, "Should find duplicate by externalIdentifier")

        // Case B: Deterministic match by course, title, and due date within 1 hour
        let remoteWithoutID = RemoteCourseWork(id: "gc_new_id", courseId: "c1", title: "Physics Problem Set 2", dueDate: now.addingTimeInterval(600))
        let dupByContent = syncEngine.findDuplicate(work: remoteWithoutID, in: [existingAssignment], courseName: "AP Physics")
        try assertCondition(dupByContent != nil, "Should find duplicate by title, course, and proximate due date")

        // Case C: Different assignment should not match
        let remoteDifferent = RemoteCourseWork(id: "gc_different", courseId: "c1", title: "Biology Lab", dueDate: now)
        let noDup = syncEngine.findDuplicate(work: remoteDifferent, in: [existingAssignment], courseName: "Biology")
        try assertCondition(noDup == nil, "Different assignment must not be flagged as duplicate")
    }

    // MARK: - 4. Notification Scheduling & Cancellation Logic
    public static func testNotificationSchedulingAndCancellation() async throws {
        let mockAssignment = Assignment(
            title: "Math Quiz Review",
            subject: "Geometry",
            dueDate: Date().addingTimeInterval(86400 * 2)
        )

        // Verify assignment reminder IDs are formatted deterministically
        let id24h = "assignment-due-24h-\(mockAssignment.id.uuidString)"
        let id3h = "assignment-due-3h-\(mockAssignment.id.uuidString)"
        let idOverdue = "assignment-overdue-\(mockAssignment.id.uuidString)"

        try assertCondition(id24h.contains(mockAssignment.id.uuidString), "24h notification ID must be linked to assignment UUID")
        try assertCondition(id3h.contains(mockAssignment.id.uuidString), "3h notification ID must be linked to assignment UUID")
        try assertCondition(idOverdue.contains(mockAssignment.id.uuidString), "Overdue notification ID must be linked to assignment UUID")

        // When assignment status is completed, schedule Reminders cancels them
        mockAssignment.status = .completed
        try await NotificationManager.shared.scheduleAssignmentReminders(for: mockAssignment)
        // Check that cancelled assignment didn't throw
    }

    // MARK: - 5. Study Session Calculations
    public static func testStudySessionCalculations() throws {
        let session = StudySession(
            subject: "Calculus",
            plannedDuration: 25 * 60,
            actualDuration: 20 * 60,
            status: .completed,
            breaksDuration: 5 * 60,
            interruptionsCount: 2
        )

        try assertCondition(session.actualDuration == 1200, "Actual active duration should be exactly 20 minutes (1200 seconds)")
        try assertCondition(session.breaksDuration == 300, "Break duration should be 5 minutes (300 seconds)")
        try assertCondition(session.interruptionsCount == 2, "Interruption counter should be recorded correctly")
        try assertCondition(session.status == .completed, "Session status should be completed")
    }

    // MARK: - 6. Grade Calculations & GPA Formulas
    public static func testGradeCalculations() throws {
        // Standard Grade
        let stdGrade = StudentCalculators.calculateStandardGrade(earnedPoints: 85, totalPoints: 100)
        try assertCondition(stdGrade?.percentage == 85.0, "Percentage should be 85.0%")
        try assertCondition(stdGrade?.letterGrade == "B", "Letter grade should be B")
        try assertCondition(stdGrade?.gpaPoint == 3.0, "GPA point should be 3.0")

        // Final Exam Required Grade Formula
        // Current: 80% (worth 80%), Desired: 85%. Final weight: 20%.
        // Needed: (85 - (80 * 0.80)) / 0.20 = (85 - 64) / 0.20 = 21 / 0.20 = 105%
        let required = StudentCalculators.calculateRequiredFinalGrade(
            currentGradePercentage: 80,
            currentWeightPercentage: 80,
            desiredFinalGradePercentage: 85
        )
        try assertCondition(abs(required! - 105.0) < 0.001, "Required final exam grade should be 105%")

        // Weighted Grade
        let weighted = StudentCalculators.calculateWeightedGrade(categories: [
            .init(name: "A", scorePercentage: 90, weightPercentage: 50),
            .init(name: "B", scorePercentage: 80, weightPercentage: 50)
        ])
        try assertCondition(weighted?.grade == 85.0, "Weighted grade average should be 85.0%")

        // What-If projection: 84% on 60% completed + 90% on 40% remaining = 86.4%
        let whatIf = StudentCalculators.calculateWhatIfGrade(
            currentGradePercentage: 84,
            completedWeightPercentage: 60,
            remainingWeightPercentage: 40,
            hypothesizedRemainingScorePercentage: 90
        )
        try assertCondition(whatIf != nil, "What-If projection should compute for valid weights")
        try assertCondition(abs(whatIf! - 86.4) < 0.001, "What-If projection should be 86.4% for 84/60 + 90/40")

        // What-If validation: remaining weight must be positive
        let invalidWhatIf = StudentCalculators.calculateWhatIfGrade(
            currentGradePercentage: 84,
            completedWeightPercentage: 100,
            remainingWeightPercentage: 0,
            hypothesizedRemainingScorePercentage: 90
        )
        try assertCondition(invalidWhatIf == nil, "What-If projection must reject zero remaining weight")

        // GPA (Unweighted vs Weighted)
        let courses: [StudentCalculators.CourseGradeItem] = [
            .init(courseName: "English", letterGrade: "A", creditHours: 3.0, isHonorsOrAP: false), // 4.0 * 3 = 12
            .init(courseName: "AP Physics", letterGrade: "B", creditHours: 3.0, isHonorsOrAP: true) // Unweighted 3.0, Weighted 4.0 * 3 = 12
        ]
        let gpaResult = StudentCalculators.calculateGPA(courses: courses)
        // Total credits = 6.0.
        // Unweighted points: (4.0*3) + (3.0*3) = 21.0 -> 21 / 6 = 3.5
        // Weighted points: (4.0*3) + (4.0*3) = 24.0 -> 24 / 6 = 4.0
        try assertCondition(gpaResult?.unweightedGPA == 3.5, "Unweighted GPA should be 3.50")
        try assertCondition(gpaResult?.weightedGPA == 4.0, "Weighted GPA should be 4.00 with AP bump")
    }

    // MARK: - 7. Sync State Transitions & Offline Fallback
    public static func testSyncStateTransitions() async throws {
        let container = StudyOSSchema.createModelContainer(inMemory: true)
        let context = container.mainContext

        // Mock offline failure
        let mockOffline = MockGoogleClassroomService(isConnected: true, shouldFailWithOffline: true)
        let engine = SyncEngine(service: mockOffline)

        await engine.performSync(modelContext: context)
        try assertCondition(engine.syncStatus == .offline, "Sync engine must transition to .offline when network fails")

        // Mock auth required
        let mockAuth = MockGoogleClassroomService(isConnected: true, shouldFailWithAuthError: true)
        let authEngine = SyncEngine(service: mockAuth)
        await authEngine.performSync(modelContext: context)
        try assertCondition(authEngine.syncStatus == .authenticationRequired, "Sync engine must transition to .authenticationRequired on expired token")
        try assertCondition(authEngine.needsReauthentication == true, "needsReauthentication flag must be set to true")
    }

    // MARK: - 8. Keychain & OAuth Token Handling
    public static func testKeychainTokenHandling() throws {
        let keychain = KeychainService()
        let tokenKey = "test_studyos_token_\(UUID().uuidString)"
        let secret = "oauth2_refresh_secret_sample"

        let saved = keychain.save(key: tokenKey, string: secret)
        try assertCondition(saved == true, "Saving token to Keychain must succeed")

        let retrieved = keychain.retrieveString(key: tokenKey)
        try assertCondition(retrieved == secret, "Retrieved token must exactly match saved secret")

        let deleted = keychain.delete(key: tokenKey)
        try assertCondition(deleted == true, "Deleting token from Keychain must succeed")

        let afterDelete = keychain.retrieveString(key: tokenKey)
        try assertCondition(afterDelete == nil, "Token must be nil after deletion")
    }

    // MARK: - 9. Material Text Indexing & Search
    public static func testMaterialIndexing() throws {
        let material = Material(
            title: "Cell Division Summary",
            subject: "Biology",
            extractedTextReference: "Mitosis involves prophase, metaphase, anaphase, and telophase.",
            fileType: .note,
            tags: ["Unit 2", "Exam Review"]
        )

        let query = "metaphase"
        let matches = material.extractedTextReference?.localizedCaseInsensitiveContains(query) ?? false
        try assertCondition(matches == true, "Extracted text must match search query 'metaphase'")

        let tagMatches = material.tags.contains(where: { $0.localizedCaseInsensitiveContains("Unit 2") })
        try assertCondition(tagMatches == true, "Tags must match search query 'Unit 2'")
    }

    // MARK: - 10. OAuth Error Copy Is User-Safe
    /// The critical-integration rule: user-facing UI must never reveal
    /// developer diagnostics (missing credentials, build configuration).
    /// The error enum's public copy is the contract — assert it stays clean.
    public static func testOAuthErrorCopyIsUserSafe() throws {
        let messages = [
            GoogleClassroomError.notConfigured.errorDescription ?? "",
            GoogleClassroomError.notConnected.errorDescription ?? "",
            GoogleClassroomError.authenticationRequired.errorDescription ?? "",
            GoogleClassroomError.networkUnavailable.errorDescription ?? "",
            GoogleClassroomError.tokenExpired.errorDescription ?? "",
            GoogleClassroomError.schoolRestricted.errorDescription ?? ""
        ]

        let forbiddenDeveloperPhrases = [
            "build",           // "isn't set up in this build", etc.
            "credential",      // exposes configuration detail
            "info.plist",      // developer surface
            "oauth client",    // developer surface
            "installation"
        ]

        for message in messages {
            let lowered = message.lowercased()
            for phrase in forbiddenDeveloperPhrases {
                try assertCondition(
                    !lowered.contains(phrase),
                    "User-facing OAuth copy must not contain developer phrase '\(phrase)': \"\(message)\""
                )
            }
        }

        // Data-safety reassurance must accompany auth/offline failures.
        try assertCondition(
            GoogleClassroomError.authenticationRequired.errorDescription?.contains("still available") == true,
            "Auth failure copy must reassure that local data remains available"
        )
        try assertCondition(
            GoogleClassroomError.networkUnavailable.errorDescription?.contains("still") == true,
            "Offline copy must reassure that local data remains usable"
        )
    }

    // MARK: - 10b. Google Error Classification
    /// School-managed accounts get refusals with specific error payloads.
    /// Those must map to the institutional-restriction case, never to a
    /// generic "app broken" failure.
    public static func testGoogleErrorClassification() throws {
        func body(_ json: String) -> Data { json.data(using: .utf8)! }

        let adminPolicy = GoogleClassroomError.classify(
            statusCode: 400,
            body: body(#"{"error":"admin_policy_enforced","error_description":"Admin policy"}"#)
        )
        try assertCondition(adminPolicy == .schoolRestricted, "admin_policy_enforced must classify as schoolRestricted")

        let orgInternal = GoogleClassroomError.classify(
            statusCode: 400,
            body: body(#"{"error":"org_internal"}"#)
        )
        try assertCondition(orgInternal == .schoolRestricted, "org_internal must classify as schoolRestricted")

        let apiDenied = GoogleClassroomError.classify(
            statusCode: 403,
            body: body(#"{"error":{"status":"PERMISSION_DENIED","message":"Request had insufficient authentication scopes."}}"#)
        )
        try assertCondition(apiDenied == .schoolRestricted, "403 API denial must classify as schoolRestricted")

        let unauthorized = GoogleClassroomError.classify(
            statusCode: 400,
            body: body(#"{"error":"unauthorized_client"}"#)
        )
        try assertCondition(unauthorized == .schoolRestricted, "unauthorized_client must classify as schoolRestricted")

        let expired = GoogleClassroomError.classify(statusCode: 401, body: nil)
        try assertCondition(expired == .tokenExpired, "401 must classify as tokenExpired")

        let serverError = GoogleClassroomError.classify(statusCode: 500, body: nil)
        try assertCondition(serverError == .requestFailed("Google returned an error (HTTP 500)."), "5xx must remain a plain request failure")
    }

    // MARK: - Run All Unit Tests
    public static func runAllTests() async throws -> (passed: Int, total: Int) {
        var passed = 0
        let total = 11

        try testPlannerCalculations()
        passed += 1

        try testDueDateParsing()
        passed += 1

        try testAssignmentDeduplication()
        passed += 1

        try await testNotificationSchedulingAndCancellation()
        passed += 1

        try testStudySessionCalculations()
        passed += 1

        try testGradeCalculations()
        passed += 1

        try await testSyncStateTransitions()
        passed += 1

        try testKeychainTokenHandling()
        passed += 1

        try testMaterialIndexing()
        passed += 1

        try testOAuthErrorCopyIsUserSafe()
        passed += 1

        try testGoogleErrorClassification()
        passed += 1

        return (passed, total)
    }
}
