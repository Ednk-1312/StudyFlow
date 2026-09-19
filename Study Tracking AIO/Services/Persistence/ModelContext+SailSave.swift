//
//  ModelContext+SafeSave.swift
//  StudyOS
//

import Foundation
import SwiftData

/// Error thrown when persisting local data fails. Local saves are the app's
/// foundation, so failures are surfaced instead of discarded with `try?`.
public struct ModelContextSaveError: LocalizedError {
    public let underlying: Error

    public init(_ underlying: Error) {
        self.underlying = underlying
    }

    public var errorDescription: String? {
        "StudyOS couldn't save your change. Your existing data is untouched."
    }
}

extension ModelContext {
    /// Saves the context, throwing a descriptive error instead of silently
    /// swallowing persistence failures on important operations.
    public func saveOrThrow() throws {
        do {
            try save()
        } catch {
            throw ModelContextSaveError(error)
        }
    }
}
