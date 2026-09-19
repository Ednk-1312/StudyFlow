//
//  SyncEngine.swift
//  StudyOS
//

import Foundation
import SwiftData
import Observation

@Observable
public final class SyncEngine: @unchecked Sendable {
    public static let shared = SyncEngine()

    public private(set) var syncStatus: SyncStatus = .idle
    public private(set) var lastSuccessfulSyncDate: Date?
    public private(set) var lastSyncAttemptDate: Date?
    public private(set) var lastSyncError: String?
    public private(set) var isSyncing: Bool = false
    public private(set) var needsReauthentication: Bool = false

    private let service: GoogleClassroomServiceProtocol
    private var currentSyncTask: Task<Void, Never>?
    private let maxRetries = 3
    private let initialBackoffSeconds: Double = 1.0

    public init(service: GoogleClassroomServiceProtocol = GoogleClassroomService.shared) {
        self.service = service
    }

    public func cancelSync() {
        currentSyncTask?.cancel()
        currentSyncTask = nil
        if isSyncing {
            isSyncing = false
            syncStatus = .idle
        }
    }

    @MainActor
    public func performSync(modelContext: ModelContext) async {
        guard !isSyncing else { return }

        guard service.isConnected else {
            syncStatus = .idle
            return
        }

        if service.needsReauthorization {
            syncStatus = .authenticationRequired
            needsReauthentication = true
            return
        }

        isSyncing = true
        syncStatus = .syncing
        lastSyncAttemptDate = Date()
        lastSyncError = nil

        let task = Task { [weak self] () -> Void in
            guard let self = self else { return }
            await self.executeSyncWithBackoff(modelContext: modelContext)
        }
        self.currentSyncTask = task
        await task.value
    }

    @MainActor
    private func executeSyncWithBackoff(modelContext: ModelContext) async {
        var attempt = 0
        var delay = initialBackoffSeconds

        while attempt < maxRetries {
            if Task.isCancelled {
                isSyncing = false
                syncStatus = .idle
                return
            }

            do {
                try await syncData(modelContext: modelContext)
                let now = Date()
                lastSuccessfulSyncDate = now
                syncStatus = .success(now)
                isSyncing = false
                needsReauthentication = false
                return
            } catch let error as GoogleClassroomError {
                switch error {
                case .networkUnavailable:
                    syncStatus = .offline
                    lastSyncError = error.localizedDescription
                    isSyncing = false
                    return
                case .authenticationRequired, .tokenExpired:
                    syncStatus = .authenticationRequired
                    needsReauthentication = true
                    lastSyncError = error.localizedDescription
                    isSyncing = false
                    return
                case .cancelled:
                    syncStatus = .idle
                    isSyncing = false
                    return
                case .notConnected:
                    syncStatus = .idle
                    isSyncing = false
                    return
                case .notConfigured:
                    syncStatus = .idle
                    lastSyncError = error.localizedDescription
                    isSyncing = false
                    return
                case .schoolRestricted:
                    // Institutional block, not a transient failure: do not
                    // retry. The user keeps all local functionality.
                    syncStatus = .failed(error.localizedDescription)
                    lastSyncError = error.localizedDescription
                    needsReauthentication = false
                    isSyncing = false
                    return
                case .requestFailed:
                    attempt += 1
                    if attempt < maxRetries {
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        delay *= 2.0 // Exponential backoff
                    } else {
                        syncStatus = .failed(error.localizedDescription)
                        lastSyncError = error.localizedDescription
                        isSyncing = false
                        return
                    }
                }
            } catch {
                attempt += 1
                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    delay *= 2.0
                } else {
                    let desc = error.localizedDescription
                    syncStatus = .failed(desc)
                    lastSyncError = desc
                    isSyncing = false
                    return
                }
            }
        }
    }

    @MainActor
    private func syncData(modelContext: ModelContext) async throws {
        // Fetch remote courses
        let remoteCourses = try await service.fetchCourses()
        let existingCourses = try modelContext.fetch(FetchDescriptor<Course>())

        for remoteCourse in remoteCourses {
            if let existing = existingCourses.first(where: { $0.externalIdentifier == remoteCourse.id }) {
                existing.name = remoteCourse.name
                existing.teacherName = remoteCourse.teacherName
                existing.updatedAt = Date()
            } else {
                let newCourse = Course(
                    name: remoteCourse.name,
                    teacherName: remoteCourse.teacherName,
                    externalIdentifier: remoteCourse.id,
                    source: .googleClassroom
                )
                modelContext.insert(newCourse)
            }
        }

        // Fetch coursework for each course
        let existingAssignments = try modelContext.fetch(FetchDescriptor<Assignment>())

        for remoteCourse in remoteCourses {
            let remoteWork = try await service.fetchCourseWork(courseId: remoteCourse.id)

            for work in remoteWork {
                guard let dueDate = work.dueDate else { continue }

                // Deterministic duplicate detection
                let duplicate = findDuplicate(work: work, in: existingAssignments, courseName: remoteCourse.name)

                if let existing = duplicate {
                    // Update only if user hasn't marked it completed and notes are preserved
                    if existing.status != .completed {
                        existing.dueDate = dueDate
                        existing.title = work.title
                        existing.lastSyncedAt = Date()
                        existing.updatedAt = Date()
                    }
                } else {
                    let newAssignment = Assignment(
                        title: work.title,
                        subject: remoteCourse.name,
                        courseName: remoteCourse.name,
                        dueDate: dueDate,
                        estimatedMinutes: 45,
                        priority: .medium,
                        status: .notStarted,
                        notes: work.description ?? "",
                        source: .googleClassroom,
                        externalIdentifier: work.id,
                        lastSyncedAt: Date()
                    )
                    modelContext.insert(newAssignment)
                }
            }
        }

        try modelContext.save()
    }

    public func findDuplicate(work: RemoteCourseWork, in existing: [Assignment], courseName: String) -> Assignment? {
        // 1. Match by externalIdentifier
        if let byId = existing.first(where: { $0.externalIdentifier == work.id }) {
            return byId
        }

        // 2. Deterministic matching by course, title, and dueDate (within 1 hour)
        guard let remoteDate = work.dueDate else { return nil }
        return existing.first(where: { assignment in
            assignment.courseName.caseInsensitiveCompare(courseName) == .orderedSame &&
            assignment.title.caseInsensitiveCompare(work.title) == .orderedSame &&
            abs(assignment.dueDate.timeIntervalSince(remoteDate)) < 3600
        })
    }
}
