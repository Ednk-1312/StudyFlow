//
//  Course.swift
//  StudyOS
//

import Foundation
import SwiftData

public enum CourseSource: String, Codable, CaseIterable {
    case manual = "Manual"
    case googleClassroom = "Google Classroom"
}

@Model
public final class Course {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var teacherName: String?
    public var externalIdentifier: String?
    public var sourceRaw: String
    public var colorHex: String
    public var createdAt: Date
    public var updatedAt: Date

    public var source: CourseSource {
        get { CourseSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        name: String,
        teacherName: String? = nil,
        externalIdentifier: String? = nil,
        source: CourseSource = .manual,
        colorHex: String = "#0A84FF",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.teacherName = teacherName
        self.externalIdentifier = externalIdentifier
        self.sourceRaw = source.rawValue
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
