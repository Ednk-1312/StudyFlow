//
//  GoogleClassroomService.swift
//  StudyOS
//

import Foundation
import AuthenticationServices
#if canImport(AppKit)
import AppKit
#endif

/// Configuration for the Google OAuth flow. These values are injected rather
/// than hardcoded so the app build stays honest: without a configured client,
/// connecting Google Classroom is presented as unavailable instead of faked.
public struct GoogleOAuthConfiguration: Sendable {
    public let clientID: String
    public let redirectURI: String

    public init(clientID: String, redirectURI: String) {
        self.clientID = clientID
        self.redirectURI = redirectURI
    }

    /// Reads configuration from the Info.plist (GIDClientID / GIDRedirectURI
    /// keys or plain GoogleClientID / GoogleRedirectURI). Returns nil when the
    /// developer has not configured OAuth credentials.
    public static func fromInfoPlist() -> GoogleOAuthConfiguration? {
        guard
            let clientID = Bundle.main.object(forInfoDictionaryKey: "GoogleClientID") as? String,
            !clientID.isEmpty,
            let redirectURI = Bundle.main.object(forInfoDictionaryKey: "GoogleRedirectURI") as? String,
            !redirectURI.isEmpty
        else { return nil }
        return GoogleOAuthConfiguration(clientID: clientID, redirectURI: redirectURI)
    }
}

public final class GoogleClassroomService: GoogleClassroomServiceProtocol, @unchecked Sendable {
    public static let shared = GoogleClassroomService()

    private let keychain: KeychainServiceProtocol
    private let session: URLSession
    private let configuration: GoogleOAuthConfiguration?

    private let tokenKey = "google_classroom_access_token"
    private let refreshTokenKey = "google_classroom_refresh_token"
    private let tokenExpiryKey = "google_classroom_token_expiry"

    public static let scopes = [
        "https://www.googleapis.com/auth/classroom.courses.readonly",
        "https://www.googleapis.com/auth/classroom.coursework.me.readonly"
    ]

    private static let apiBaseURL = URL(string: "https://classroom.googleapis.com/v1")!

    public init(
        keychain: KeychainServiceProtocol = KeychainService.shared,
        session: URLSession = .shared,
        configuration: GoogleOAuthConfiguration? = .fromInfoPlist()
    ) {
        self.keychain = keychain
        self.session = session
        self.configuration = configuration
    }

    /// True when the developer has shipped OAuth credentials. Connection UI
    /// should be hidden or marked unavailable otherwise.
    public var isConfigured: Bool {
        configuration != nil
    }

    public var isConnected: Bool {
        keychain.retrieveString(key: tokenKey) != nil
    }

    public var needsReauthorization: Bool {
        guard isConnected else { return false }
        // A refresh token lets us recover from expiry silently.
        if keychain.retrieveString(key: refreshTokenKey) != nil {
            return false
        }
        if let expiryString = keychain.retrieveString(key: tokenExpiryKey),
           let expiryTime = Double(expiryString) {
            return Date() >= Date(timeIntervalSince1970: expiryTime)
        }
        return false
    }

    // MARK: - Authentication

    /// Starts the Google OAuth authorization flow via ASWebAuthenticationSession.
    /// Throws .notConfigured when no client credentials are bundled.
    public func authenticate() async throws -> Bool {
        guard let configuration else {
            throw GoogleClassroomError.notConfigured
        }

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        let state = UUID().uuidString
        components.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Self.scopes.joined(separator: " ")),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent"),
            URLQueryItem(name: "state", value: state)
        ]

        let authorizationURL = components.url!
        let redirectScheme = URL(string: configuration.redirectURI)?.scheme ?? ""

        let authorizationCode: String = try await withCheckedThrowingContinuation { continuation in
            var webSession: ASWebAuthenticationSession?
            webSession = ASWebAuthenticationSession(url: authorizationURL, callbackURLScheme: redirectScheme) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: GoogleClassroomError.requestFailed(error.localizedDescription))
                    return
                }
                guard let callbackURL,
                      let params = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems,
                      let returnedState = params.first(where: { $0.name == "state" })?.value,
                      returnedState == state,
                      let code = params.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: GoogleClassroomError.requestFailed("Authorization was incomplete."))
                    return
                }
                continuation.resume(returning: code)
            }
            webSession?.presentationContextProvider = Self.presentationContextProvider
            webSession?.start()
        }

        try await exchangeCodeForTokens(authorizationCode, configuration: configuration)
        return true
    }

    private static let presentationContextProvider = AuthenticationPresentationContextProvider()

    private func exchangeCodeForTokens(_ code: String, configuration: GoogleOAuthConfiguration) async throws {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var body = URLComponents()
        body.queryItems = [
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        request.httpBody = body.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GoogleClassroomError.requestFailed("Unexpected token response.")
        }
        guard (200..<300).contains(http.statusCode) else {
            // School-managed accounts are refused here with policy errors;
            // surface the institutional reason, not a generic failure.
            throw GoogleClassroomError.classify(statusCode: http.statusCode, body: data)
        }

        struct TokenResponse: Decodable {
            let access_token: String
            let refresh_token: String?
            let expires_in: Double
        }
        let tokenResponse: TokenResponse
        do {
            tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        } catch {
            throw GoogleClassroomError.requestFailed("Token response was malformed.")
        }

        let expiry = Date().addingTimeInterval(tokenResponse.expires_in)
        _ = keychain.save(key: tokenKey, string: tokenResponse.access_token)
        _ = keychain.save(key: tokenExpiryKey, string: String(expiry.timeIntervalSince1970))
        if let refresh = tokenResponse.refresh_token {
            _ = keychain.save(key: refreshTokenKey, string: refresh)
        }
    }

    public func disconnect() async {
        _ = keychain.delete(key: tokenKey)
        _ = keychain.delete(key: refreshTokenKey)
        _ = keychain.delete(key: tokenExpiryKey)
    }

    // MARK: - Token Management

    /// Returns a currently-valid access token, refreshing via the stored
    /// refresh token when needed. Throws when reauthorization is required.
    private func currentAccessToken() async throws -> String {
        guard let token = keychain.retrieveString(key: tokenKey) else {
            throw GoogleClassroomError.notConnected
        }
        guard let expiryString = keychain.retrieveString(key: tokenExpiryKey),
              let expiryTime = Double(expiryString),
              Date() < Date(timeIntervalSince1970: expiryTime - 60) else {
            return try await refreshAccessToken(existingToken: token)
        }
        return token
    }

    private func refreshAccessToken(existingToken: String) async throws -> String {
        guard let configuration,
              let refreshToken = keychain.retrieveString(key: refreshTokenKey) else {
            throw GoogleClassroomError.tokenExpired
        }

        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var body = URLComponents()
        body.queryItems = [
            URLQueryItem(name: "refresh_token", value: refreshToken),
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "grant_type", value: "refresh_token")
        ]
        request.httpBody = body.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GoogleClassroomError.requestFailed("Unexpected refresh response.")
        }
        if http.statusCode == 401 {
            throw GoogleClassroomError.tokenExpired
        }
        guard (200..<300).contains(http.statusCode) else {
            throw GoogleClassroomError.classify(statusCode: http.statusCode, body: data)
        }

        struct RefreshResponse: Decodable {
            let access_token: String
            let expires_in: Double
        }
        let refreshResponse: RefreshResponse
        do {
            refreshResponse = try JSONDecoder().decode(RefreshResponse.self, from: data)
        } catch {
            throw GoogleClassroomError.requestFailed("Refresh response was malformed.")
        }

        let expiry = Date().addingTimeInterval(refreshResponse.expires_in)
        _ = keychain.save(key: tokenKey, string: refreshResponse.access_token)
        _ = keychain.save(key: tokenExpiryKey, string: String(expiry.timeIntervalSince1970))
        return refreshResponse.access_token
    }

    // MARK: - API Requests

    private func authorizedGet<T: Decodable>(path: String, queryItems: [URLQueryItem] = [], responseType: T.Type) async throws -> T {
        let token = try await currentAccessToken()

        var components = URLComponents(url: Self.apiBaseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw GoogleClassroomError.requestFailed("Invalid request URL.")
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost, .cannotConnectToHost:
                throw GoogleClassroomError.networkUnavailable
            default:
                throw GoogleClassroomError.requestFailed(urlError.localizedDescription)
            }
        }

        guard let http = response as? HTTPURLResponse else {
            throw GoogleClassroomError.requestFailed("Unexpected response.")
        }
        switch http.statusCode {
        case 200..<300:
            break
        default:
            throw GoogleClassroomError.classify(statusCode: http.statusCode, body: data)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw GoogleClassroomError.requestFailed("Classroom response was malformed.")
        }
    }

    public func fetchCourses() async throws -> [RemoteCourse] {
        guard isConnected else {
            throw GoogleClassroomError.notConnected
        }

        struct CoursesResponse: Decodable {
            struct CourseItem: Decodable {
                let id: String
                let name: String
                let section: String?
                let room: String?
                let teacherFolder: JSONAny?
                let teachers: [TeacherRef]?
            }
            struct TeacherRef: Decodable {
                let profile: ProfileRef
            }
            struct ProfileRef: Decodable {
                let name: NameRef
            }
            struct NameRef: Decodable {
                let fullName: String?
            }
            struct JSONAny: Decodable {}

            let courses: [CourseItem]?
        }

        let response = try await authorizedGet(
            path: "courses",
            queryItems: [URLQueryItem(name: "courseStates", value: "ACTIVE")],
            responseType: CoursesResponse.self
        )

        return (response.courses ?? []).map { course in
            RemoteCourse(
                id: course.id,
                name: course.name,
                section: course.section,
                teacherName: course.teachers?.first?.profile.name.fullName,
                room: course.room
            )
        }
    }

    public func fetchCourseWork(courseId: String) async throws -> [RemoteCourseWork] {
        guard isConnected else {
            throw GoogleClassroomError.notConnected
        }

        struct CourseWorkResponse: Decodable {
            struct WorkItem: Decodable {
                let id: String
                let title: String
                let description: String?
                let alternateLink: String?
                let maxPoints: Double?
                let state: String?
                let dueDate: DueDateParts?
            }
            struct DueDateParts: Decodable {
                let year: Int
                let month: Int
                let day: Int
                let hours: Int?
                let minutes: Int?
            }

            let courseWork: [WorkItem]?
        }

        let response = try await authorizedGet(
            path: "courses/\(courseId)/courseWork",
            responseType: CourseWorkResponse.self
        )

        return (response.courseWork ?? []).compactMap { work in
            // Coursework without a due date cannot drive reminders or planning,
            // so it is surfaced only when one exists.
            guard let due = work.dueDate else { return nil }

            var components = DateComponents()
            components.year = due.year
            components.month = due.month
            components.day = due.day
            components.hour = due.hours ?? 23
            components.minute = due.minutes ?? 59
            guard let dueDate = Calendar.current.date(from: components) else { return nil }

            return RemoteCourseWork(
                id: work.id,
                courseId: courseId,
                title: work.title,
                description: work.description,
                dueDate: dueDate,
                maxPoints: work.maxPoints,
                alternateLink: work.alternateLink,
                state: work.state
            )
        }
    }
}

/// Presents the ASWebAuthenticationSession from the foreground window scene.
@MainActor
final class AuthenticationPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding, Sendable {
    // A key window always exists when sign-in can be presented, so it is the
    // normal anchor. The empty-window fallback is effectively unreachable but
    // the protocol requires a non-optional return; iOS 26 deprecates
    // UIWindow.init(), and the matching deprecation here records that the old
    // behavior is intentional in that dead path.
    @available(iOS, deprecated: 26.0)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if os(macOS)
        // On macOS the anchor is the key NSWindow.
        if let keyWindow = NSApp.keyWindow {
            return keyWindow
        }
        return NSApp.windows.first
            ?? NSWindow(contentRect: .zero, styleMask: [], backing: .buffered, defer: false)
        #else
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            if let keyWindow = scene.windows.first(where: \.isKeyWindow) {
                return keyWindow
            }
        }
        return ASPresentationAnchor()
        #endif
    }
}
