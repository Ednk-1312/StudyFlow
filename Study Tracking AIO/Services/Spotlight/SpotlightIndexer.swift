//
//  SpotlightIndexer.swift
//  StudyOS
//

import Foundation
import CoreSpotlight
import UniformTypeIdentifiers

public final class SpotlightIndexer: Sendable {
    public static let shared = SpotlightIndexer()

    public init() {}

    public func indexAssignment(_ assignment: Assignment) {
        guard CSSearchableIndex.isIndexingAvailable() else { return }

        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
        attributeSet.title = assignment.title
        attributeSet.contentDescription = "\(assignment.courseName) • Due \(DateFormatter.localizedString(from: assignment.dueDate, dateStyle: .medium, timeStyle: .short))"
        attributeSet.keywords = [assignment.title, assignment.subject, assignment.courseName, "Assignment", "Homework"]
        attributeSet.dueDate = assignment.dueDate

        let item = CSSearchableItem(
            uniqueIdentifier: "assignment-\(assignment.id.uuidString)",
            domainIdentifier: "com.studyos.assignments",
            attributeSet: attributeSet
        )

        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                // Log locally without leaking private text
                _ = error
            }
        }
    }

    public func deindexAssignment(id: UUID) {
        guard CSSearchableIndex.isIndexingAvailable() else { return }
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ["assignment-\(id.uuidString)"], completionHandler: nil)
    }

    public func indexMaterial(_ material: Material) {
        guard CSSearchableIndex.isIndexingAvailable() else { return }

        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
        attributeSet.title = material.title
        attributeSet.contentDescription = "\(material.subject) • \(material.fileType.rawValue)"
        attributeSet.keywords = [material.title, material.subject, material.fileType.rawValue] + material.tags
        if let text = material.extractedTextReference {
            attributeSet.textContent = String(text.prefix(1000))
        }

        let item = CSSearchableItem(
            uniqueIdentifier: "material-\(material.id.uuidString)",
            domainIdentifier: "com.studyos.materials",
            attributeSet: attributeSet
        )

        CSSearchableIndex.default().indexSearchableItems([item], completionHandler: nil)
    }

    /// Removes every StudyOS item from Spotlight. Used by Delete All Local
    /// Data so no stale entries survive the wipe.
    public func deindexAll() {
        CSSearchableIndex.default().deleteAllSearchableItems { _ in }
    }

    public func deindexMaterial(id: UUID) {
        guard CSSearchableIndex.isIndexingAvailable() else { return }
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ["material-\(id.uuidString)"], completionHandler: nil)
    }
}
