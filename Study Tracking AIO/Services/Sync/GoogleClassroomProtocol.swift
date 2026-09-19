//
//  GoogleClassroomProtocol.swift
//  StudyOS
//

import Foundation

public struct RemoteCourse: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
    public let section: String?
    public let teacherName: String?
    public let room: String?

    public init(id: String, name: String, section: String? = nil, teacherName: String? = nil, room: String? = nil) {
        self.id = id
        self.name = name
        self.section = section
        self.teacherName = teacherName
        self.room = room
    }
}

public struct RemoteCourseWork: Identifiable, Codable, Sendable {
    public let id: String
    public let courseId: String
    public let title: String
    public let description: String?
    public let dueDate: Date?
    public let maxPoints: Double?
    public let alternateLink: String?
    public let state: String?

    public init(
        id: String,
        courseId: String,
        title: String,
        description: String? = nil,
        dueDate: Date? = nil,
        maxPoints: Double? = nil,
        alternateLink: String? = nil,
        state: String? = nil
    ) {
        self.id = id
        self.courseId = courseId
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.maxPoints = maxPoints
        self.alternateLink = alternateLink
        self.state = state
    }
}

public enum GoogleClassroomError: LocalizedError, Equatable {
    case notConfigured
    case notConnected
    case authenticationRequired
    case networkUnavailable
    case tokenExpired
    case schoolRestricted
    case requestFailed(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            // User-safe wording. Developers can check the concrete case in
            // Diagnostics, which reports the raw enum — never the token.
            return "Google Classroom sign-in isn't available right now."
        case .notConnected:
            return "Google Classroom is not connected."
        case .authenticationRequired:
            return "Google Classroom needs to be reconnected. Your saved assignments are still available."
        case .networkUnavailable:
            return "No internet connection. You can still use your saved assignments."
        case .tokenExpired:
            return "Classroom session expired. Please reauthorize in Settings."
        case .schoolRestricted:
            // Institutional restriction, never a device/app malfunction.
            return "Your school is restricting this connection. StudyOS still works normally — you can add assignments manually or scan them with your camera."
        case .requestFailed(let message):
            return "Google Classroom sync failed: \(message)"
        case .cancelled:
            return "Sync was cancelled."
        }
    }

    /// Maps an OAuth/API error payload to the most accurate case. Google
    /// signals administrator policy blocks with specific error codes; those
    /// must never read as "the app is broken".
    public static func classify(statusCode: Int, body: Data?) -> GoogleClassroomError {
        var text = ""
        if let body, let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
            var parts: [String] = []
            // Token endpoint errors are flat ("error": "admin_policy_enforced");
            // Classroom API errors nest ("error": {"status": "PERMISSION_DENIED"}).
            if let e = json["error"] as? String { parts.append(e) }
            if let d = json["error_description"] as? String { parts.append(d) }
            if let m = json["message"] as? String { parts.append(m) }
            if let nested = json["error"] as? [String: Any] {
                if let m = nested["message"] as? String { parts.append(m) }
                if let s = nested["status"] as? String { parts.append(s) }
            }
            text = parts.joined(separator: " ").lowercased()
        }
        let policySignals = [
            "admin_policy", "denied", "org_internal",
            "unauthorized_client", "policy", "restricted"
        ]
        if policySignals.contains(where: { text.contains($0) }) {
            return .schoolRestricted
        }
        switch statusCode {
        case 401:
            return .tokenExpired
        case 403:
            return .schoolRestricted
        default:
            return .requestFailed("Google returned an error (HTTP \(statusCode)).")
        }
    }
}

public protocol GoogleClassroomServiceProtocol: Sendable {
    var isConnected: Bool { get }
    var needsReauthorization: Bool { get }
    func authenticate() async throws -> Bool
    func disconnect() async
    func fetchCourses() async throws -> [RemoteCourse]
    func fetchCourseWork(courseId: String) async throws -> [RemoteCourseWork]
}

extension GoogleClassroomServiceProtocol {
    /// Whether the service has OAuth credentials available. Mocks and tests
    /// treat this as always true; the production service gates on config.
    var isConfigured: Bool { true }
}
