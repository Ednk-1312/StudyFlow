//
//  AppPreferences.swift
//  StudyOS
//

import Foundation

/// Centralized, testable access to the small set of user preferences the app
/// persists in UserDefaults. All keys live here — never scattered as strings.
public struct AppPreferences: Sendable {
    public static let shared = AppPreferences(defaults: .standard)

    private let defaults: UserDefaults
    private static let hasCompletedOnboardingKey = "studyos.hasCompletedOnboarding"

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Self.hasCompletedOnboardingKey) }
        set { defaults.set(newValue, forKey: Self.hasCompletedOnboardingKey) }
    }
}
