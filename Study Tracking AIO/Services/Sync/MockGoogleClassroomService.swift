//
//  MockGoogleClassroomService.swift
//  StudyOS
//

import Foundation

public final class MockGoogleClassroomService: GoogleClassroomServiceProtocol, @unchecked Sendable {
    public var isConnected: Bool
    public var needsReauthorization: Bool
    public var shouldFailWithOffline: Bool
    public var shouldFailWithAuthError: Bool
    public var coursesToReturn: [RemoteCourse]
    public var courseworkToReturn: [String: [RemoteCourseWork]]

    public init(
        isConnected: Bool = true,
        needsReauthorization: Bool = false,
        shouldFailWithOffline: Bool = false,
        shouldFailWithAuthError: Bool = false,
        courses: [RemoteCourse] = [],
        coursework: [String: [RemoteCourseWork]] = [:]
    ) {
        self.isConnected = isConnected
        self.needsReauthorization = needsReauthorization
        self.shouldFailWithOffline = shouldFailWithOffline
        self.shouldFailWithAuthError = shouldFailWithAuthError
        self.coursesToReturn = courses
        self.courseworkToReturn = coursework
    }

    public func authenticate() async throws -> Bool {
        if shouldFailWithOffline {
            throw GoogleClassroomError.networkUnavailable
        }
        isConnected = true
        needsReauthorization = false
        return true
    }

    public func disconnect() async {
        isConnected = false
        needsReauthorization = false
    }

    public func fetchCourses() async throws -> [RemoteCourse] {
        if shouldFailWithOffline {
            throw GoogleClassroomError.networkUnavailable
        }
        if shouldFailWithAuthError || needsReauthorization {
            throw GoogleClassroomError.authenticationRequired
        }
        guard isConnected else {
            throw GoogleClassroomError.notConnected
        }
        return coursesToReturn
    }

    public func fetchCourseWork(courseId: String) async throws -> [RemoteCourseWork] {
        if shouldFailWithOffline {
            throw GoogleClassroomError.networkUnavailable
        }
        if shouldFailWithAuthError || needsReauthorization {
            throw GoogleClassroomError.authenticationRequired
        }
        guard isConnected else {
            throw GoogleClassroomError.notConnected
        }
        return courseworkToReturn[courseId] ?? []
    }
}
