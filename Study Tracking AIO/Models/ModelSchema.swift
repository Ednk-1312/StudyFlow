//
//  ModelSchema.swift
//  StudyOS
//

import Foundation
import SwiftData

public enum StudyOSSchema {
    public static let schema = Schema([
        Assignment.self,
        Course.self,
        StudySession.self,
        Material.self,
        Reminder.self,
        ExamEvent.self
    ])

    /// Explicit store location so support tooling (and the UI-test reset
    /// hook) knows exactly which files belong to the database.
    public static var storeURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("StudyOS.store")
    }

    public static func createModelContainer(inMemory: Bool = false) -> ModelContainer {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            configuration = ModelConfiguration(schema: schema, url: storeURL)
        }
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }
}
