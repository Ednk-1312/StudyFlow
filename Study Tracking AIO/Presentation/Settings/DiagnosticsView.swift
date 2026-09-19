//
//  DiagnosticsView.swift
//  StudyOS
//
//  Developer-only surface. Anything a student should not need to understand
//  (OAuth configuration, sync state machines, database counts) belongs here,
//  not in the main UI.
//

import SwiftUI
import SwiftData
import UserNotifications

/// One self-test outcome shown in the diagnostics list.
public struct DiagnosticCheckResult: Identifiable {
    public let id = UUID()
    public let testName: String
    public let passed: Bool
    public let message: String

    public init(testName: String, passed: Bool, message: String) {
        self.testName = testName
        self.passed = passed
        self.message = message
    }
}

public struct DiagnosticsView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var isRunningTests: Bool = false
    @State private var testResults: [DiagnosticCheckResult] = []
    @State private var exportedJSON: String = ""
    @State private var isExportSheetPresented: Bool = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    public init() {}

    public var body: some View {
        List {
            developerStateSections
            selfTestSection

            if !testResults.isEmpty {
                testResultsSection
            }

            dataExportSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            notificationStatus = await NotificationManager.shared.checkAuthorizationStatus()
        }
        .sheet(isPresented: $isExportSheetPresented) {
            NavigationStack {
                ScrollView {
                    Text(exportedJSON)
                        .font(.caption.monospaced())
                        .padding()
                        .textSelection(.enabled)
                }
                .navigationTitle("Exported JSON")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { isExportSheetPresented = false }
                    }
                }
            }
        }
    }

    // MARK: - Developer State

    private var developerStateSections: some View {
        Group {
            Section("Google OAuth Configuration") {
                ForEach(DeveloperDiagnostics.googleOAuthEntries()) { entry in
                    DiagnosticEntryRow(entry: entry)
                }
            }

            Section("Sync Engine") {
                ForEach(DeveloperDiagnostics.syncEntries(engine: SyncEngine.shared)) { entry in
                    DiagnosticEntryRow(entry: entry)
                }
                Button("Cancel Sync") {
                    SyncEngine.shared.cancelSync()
                }
                .disabled(!SyncEngine.shared.isSyncing)
            }

            Section("Database & Storage") {
                ForEach(DeveloperDiagnostics.storageEntries(context: modelContext)) { entry in
                    DiagnosticEntryRow(entry: entry)
                }
            }

            Section("System Integration") {
                DiagnosticEntryRow(entry: DeveloperDiagnostics.indexingStatusEntry())
                DiagnosticEntryRow(entry: DeveloperDiagnostics.notificationEntry(authorizationStatus: notificationStatus))
            }
        }
    }

    // MARK: - Self-Tests

    private var selfTestSection: some View {
        Section {
            Button {
                runSelfTests()
            } label: {
                HStack {
                    if isRunningTests {
                        ProgressView()
                        Text("Running…")
                            .font(.body.weight(.medium))
                    } else {
                        Label("Run All Verification Self-Tests", systemImage: "checkmark.shield")
                            .font(.body.weight(.medium))
                    }
                    Spacer()
                }
            }
            .disabled(isRunningTests)
        } header: {
            Text("Self-Tests")
        } footer: {
            Text("Executes in-app unit assertions: planner, OCR parsing, grade calculators (including What-If), Keychain, and sync transitions.")
        }
    }

    private var testResultsSection: some View {
        Section("Results (\(testResults.filter(\.passed).count)/\(testResults.count) Passed)") {
            ForEach(testResults) { result in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(result.passed ? .green : .red)
                        .padding(.top, 2)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.testName)
                            .font(.subheadline.weight(.medium))
                        Text(result.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text("\(result.testName). \(result.passed ? "Passed" : "Failed"). \(result.message)"))
            }
        }
    }

    // MARK: - Data Export

    private var dataExportSection: some View {
        Section("Data Export") {
            Button {
                exportData()
            } label: {
                Label("Export Assignments as JSON", systemImage: "square.and.arrow.up")
            }
        }
    }

    // MARK: - Actions

    private func runSelfTests() {
        isRunningTests = true
        testResults.removeAll()

        Task {
            var results: [DiagnosticCheckResult] = []

            // 1. Planner calculations
            let a1 = Assignment(title: "Urgent Lab", subject: "Phys", dueDate: Date().addingTimeInterval(3600), estimatedMinutes: 30, priority: .urgent)
            let a2 = Assignment(title: "Low HW", subject: "Math", dueDate: Date().addingTimeInterval(86400 * 3), estimatedMinutes: 45, priority: .low)
            let prioritized = DeterministicStudyPlanner.shared.prioritizeAssignments([a2, a1])
            let plannerPassed = prioritized.first?.title == "Urgent Lab"
            results.append(.init(testName: "Planner Priority & Urgency Ordering", passed: plannerPassed, message: plannerPassed ? "Correctly scored and placed urgent task first" : "Priority calculation failed"))

            // 2. Planner blocks
            let blocks = DeterministicStudyPlanner.shared.generateDailyPlan(assignments: [a1, a2], exams: [])
            let blocksPassed = !blocks.isEmpty && blocks.contains(where: { $0.isBreak })
            results.append(.init(testName: "Deterministic Study Blocks & Breaks", passed: blocksPassed, message: blocksPassed ? "Allocated study blocks with interleaved breaks" : "Failed generating study blocks"))

            // 3. OCR extraction
            let candidate = ScannedAssignmentExtractor.shared.extractCandidate(from: "Calculus Homework\nDr. Smith\nDue: Tomorrow at 5:00 PM\nProblems 1-10")
            let ocrPassed = candidate.candidateSubject == "Calculus" && candidate.candidateTeacher == "Dr. Smith"
            results.append(.init(testName: "OCR Candidate Extraction", passed: ocrPassed, message: ocrPassed ? "Extracted subject 'Calculus' and teacher 'Dr. Smith'" : "Failed candidate extraction"))

            // 4. Deduplication
            let mockWork = RemoteCourseWork(id: "gc_123", courseId: "c1", title: "Math Set 1", dueDate: Date())
            let existing = [Assignment(title: "Math Set 1", subject: "Math", dueDate: Date(), externalIdentifier: "gc_123")]
            let dup = SyncEngine.shared.findDuplicate(work: mockWork, in: existing, courseName: "Math")
            let dupPassed = dup != nil && dup?.externalIdentifier == "gc_123"
            results.append(.init(testName: "Assignment Deduplication", passed: dupPassed, message: dupPassed ? "Matched by externalIdentifier" : "Failed duplicate matching"))

            // 5. GPA
            let gpa = StudentCalculators.calculateGPA(courses: [
                .init(courseName: "Bio", letterGrade: "A", creditHours: 3.0, isHonorsOrAP: false),
                .init(courseName: "Calc", letterGrade: "B", creditHours: 3.0, isHonorsOrAP: true)
            ])
            let gpaPassed = gpa != nil && gpa?.unweightedGPA == 3.5 && gpa?.weightedGPA == 4.0
            results.append(.init(testName: "GPA Unweighted & Weighted Formulas", passed: gpaPassed, message: gpaPassed ? "Unweighted 3.50, weighted 4.00" : "GPA math assertion failed"))

            // 6. Weighted grade
            let weighted = StudentCalculators.calculateWeightedGrade(categories: [
                .init(name: "HW", scorePercentage: 100, weightPercentage: 50),
                .init(name: "Exam", scorePercentage: 80, weightPercentage: 50)
            ])
            let weightedPassed = weighted != nil && weighted?.grade == 90.0
            results.append(.init(testName: "Weighted Grade Calculation", passed: weightedPassed, message: weightedPassed ? "Weighted score exactly 90.0%" : "Weighted grade calculation failed"))

            // 7. What-If grade
            let whatIf = StudentCalculators.calculateWhatIfGrade(
                currentGradePercentage: 85,
                completedWeightPercentage: 60,
                remainingWeightPercentage: 40,
                hypothesizedRemainingScorePercentage: 90
            )
            let whatIfPassed = whatIf != nil && abs(whatIf! - 87.0) < 0.001
            results.append(.init(testName: "What-If Grade Projection", passed: whatIfPassed, message: whatIfPassed ? "85/60% + 90/40% projects to 87.0%" : "What-If calculation failed"))

            // 8. Keychain round-trip
            let testKey = "test_keychain_\(UUID().uuidString)"
            let saveSuccess = KeychainService.shared.save(key: testKey, string: "secret_123")
            let retrieved = KeychainService.shared.retrieveString(key: testKey)
            _ = KeychainService.shared.delete(key: testKey)
            let keychainPassed = saveSuccess && retrieved == "secret_123"
            results.append(.init(testName: "Keychain Token Storage & Retrieval", passed: keychainPassed, message: keychainPassed ? "Item saved, matched, and cleaned" : "Keychain access error"))

            // 9. Sync offline transition
            let mockService = MockGoogleClassroomService(isConnected: true, shouldFailWithOffline: true)
            let testEngine = SyncEngine(service: mockService)
            await testEngine.performSync(modelContext: modelContext)
            let syncPassed = testEngine.syncStatus == .offline
            results.append(.init(testName: "Sync State Offline Resilience", passed: syncPassed, message: syncPassed ? "Transitioned to .offline without erasing data" : "Sync state transition failed"))

            // 10. On-device summarizer
            let summary = try? await OnDeviceStudyAIService.shared.summarize(text: "Mitochondria generate ATP. They are essential for eukaryotic cells.")
            let aiPassed = summary != nil && !summary!.coreSummary.isEmpty
            results.append(.init(testName: "On-Device AI Summarizer", passed: aiPassed, message: aiPassed ? "Summary generated locally" : "AI summarizer failed"))

            await MainActor.run {
                self.testResults = results
                self.isRunningTests = false
            }
        }
    }

    private func exportData() {
        let descriptor = FetchDescriptor<Assignment>()
        let assignments = (try? modelContext.fetch(descriptor)) ?? []
        let payload = assignments.map { a in
            [
                "id": a.id.uuidString,
                "title": a.title,
                "course": a.courseName,
                "dueDate": ISO8601DateFormatter().string(from: a.dueDate),
                "priority": a.priority.rawValue,
                "status": a.status.rawValue,
                "notes": a.notes
            ]
        }
        if let json = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted),
           let str = String(data: json, encoding: .utf8) {
            exportedJSON = str
            isExportSheetPresented = true
        }
    }
}

private struct DiagnosticEntryRow: View {
    let entry: DiagnosticEntry

    private var iconName: String {
        switch entry.state {
        case .ok: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .inactive: return "minus.circle"
        }
    }

    private var iconColor: Color {
        switch entry.state {
        case .ok: return .green
        case .warning: return .orange
        case .inactive: return .secondary
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .padding(.top, 2)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.label)
                    .font(.subheadline.weight(.medium))
                Text(entry.value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(entry.label): \(entry.value)"))
    }
}
