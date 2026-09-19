//
//  Material.swift
//  StudyOS
//

import Foundation
import SwiftData

public enum MaterialFileType: String, Codable, CaseIterable {
    case note = "Note"
    case pdf = "PDF Document"
    case image = "Image"
    case worksheet = "Worksheet"
    case scan = "Scanned Document"

    public var systemImage: String {
        switch self {
        case .note: return "note.text"
        case .pdf: return "doc.richtext"
        case .image: return "photo"
        case .worksheet: return "doc.text.below.ecg"
        case .scan: return "doc.viewfinder"
        }
    }
}

@Model
public final class Material {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var subject: String
    public var localFileReference: String?
    public var extractedTextReference: String?
    public var fileTypeRaw: String
    public var tags: [String]
    public var assignmentIDs: [UUID]
    public var createdAt: Date
    public var updatedAt: Date

    public var fileType: MaterialFileType {
        get { MaterialFileType(rawValue: fileTypeRaw) ?? .note }
        set { fileTypeRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        title: String,
        subject: String,
        localFileReference: String? = nil,
        extractedTextReference: String? = nil,
        fileType: MaterialFileType = .note,
        tags: [String] = [],
        assignmentIDs: [UUID] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.subject = subject
        self.localFileReference = localFileReference
        self.extractedTextReference = extractedTextReference
        self.fileTypeRaw = fileType.rawValue
        self.tags = tags
        self.assignmentIDs = assignmentIDs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
