//
//  ScannedAssignmentExtractor.swift
//  StudyOS
//

import Foundation

public struct ExtractedAssignmentCandidate: Equatable, Sendable {
    public var rawRecognizedText: String
    public var candidateTitle: String?
    public var isTitleConfident: Bool
    public var candidateSubject: String?
    public var isSubjectConfident: Bool
    public var candidateDueDate: Date?
    public var isDueDateConfident: Bool
    public var candidateTeacher: String?
    public var isTeacherConfident: Bool
    public var candidateInstructions: String?

    public init(
        rawRecognizedText: String,
        candidateTitle: String? = nil,
        isTitleConfident: Bool = false,
        candidateSubject: String? = nil,
        isSubjectConfident: Bool = false,
        candidateDueDate: Date? = nil,
        isDueDateConfident: Bool = false,
        candidateTeacher: String? = nil,
        isTeacherConfident: Bool = false,
        candidateInstructions: String? = nil
    ) {
        self.rawRecognizedText = rawRecognizedText
        self.candidateTitle = candidateTitle
        self.isTitleConfident = isTitleConfident
        self.candidateSubject = candidateSubject
        self.isSubjectConfident = isSubjectConfident
        self.candidateDueDate = candidateDueDate
        self.isDueDateConfident = isDueDateConfident
        self.candidateTeacher = candidateTeacher
        self.isTeacherConfident = isTeacherConfident
        self.candidateInstructions = candidateInstructions
    }
}

public final class ScannedAssignmentExtractor: Sendable {
    public static let shared = ScannedAssignmentExtractor()

    public init() {}

    public func extractCandidate(from rawText: String) -> ExtractedAssignmentCandidate {
        let lines = rawText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var candidate = ExtractedAssignmentCandidate(rawRecognizedText: rawText)

        guard !lines.isEmpty else {
            return candidate
        }

        // 1. Identify Subject / Class keywords
        let subjectKeywords = ["Math", "Mathematics", "Calculus", "Algebra", "Geometry", "Biology", "Chemistry", "Physics", "Science", "History", "World History", "English", "Literature", "Spanish", "French", "Computer Science", "Economics"]

        for line in lines {
            for keyword in subjectKeywords {
                if line.localizedCaseInsensitiveContains(keyword) {
                    candidate.candidateSubject = keyword
                    candidate.isSubjectConfident = true
                    break
                }
            }
            if candidate.candidateSubject != nil { break }
        }

        // 2. Identify Teacher information (e.g. "Mr. Smith", "Mrs. Davis", "Dr. Johnson", "Teacher:")
        let teacherRegex = try? NSRegularExpression(pattern: "(?:Mr\\.|Mrs\\.|Ms\\.|Dr\\.|Teacher:?)\\s+([A-Z][a-zA-Z]+)", options: [])
        for line in lines {
            if let match = teacherRegex?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)) {
                if let range = Range(match.range, in: line) {
                    candidate.candidateTeacher = String(line[range])
                    candidate.isTeacherConfident = true
                    break
                }
            }
        }

        // 3. Identify Due Date using NSDataDetector
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
            var foundDates: [(Date, Bool)] = []
            for line in lines {
                let matches = detector.matches(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count))
                for match in matches {
                    if let date = match.date {
                        let isLabeledDue = line.localizedCaseInsensitiveContains("due") || line.localizedCaseInsensitiveContains("deadline")
                        foundDates.append((date, isLabeledDue))
                    }
                }
            }

            // Prefer explicitly labeled due dates, else first detected future/valid date
            if let labeled = foundDates.first(where: { $0.1 }) {
                candidate.candidateDueDate = labeled.0
                candidate.isDueDateConfident = true
            } else if let firstDate = foundDates.first {
                candidate.candidateDueDate = firstDate.0
                candidate.isDueDateConfident = false // Unlabeled date is marked uncertain
            }
        }

        // 4. Candidate Title: Look for keywords like "Assignment:", "Homework:", "Chapter", "Unit", or first non-metadata line
        let assignmentPrefixes = ["Assignment:", "HW:", "Homework:", "Lab:", "Project:", "Chapter", "Unit", "Problem Set"]
        for line in lines {
            for prefix in assignmentPrefixes {
                if line.localizedCaseInsensitiveContains(prefix) {
                    candidate.candidateTitle = line
                    candidate.isTitleConfident = true
                    break
                }
            }
            if candidate.candidateTitle != nil { break }
        }

        // Fallback title: the first prominent line that isn't the subject or teacher
        if candidate.candidateTitle == nil {
            for line in lines {
                let isSubject = candidate.candidateSubject != nil && line.contains(candidate.candidateSubject!)
                let isTeacher = candidate.candidateTeacher != nil && line.contains(candidate.candidateTeacher!)
                let isShortMeta = line.count < 3 || line.lowercased().contains("name:") || line.lowercased().contains("period:") || line.lowercased().contains("date:")
                if !isSubject && !isTeacher && !isShortMeta {
                    candidate.candidateTitle = line
                    candidate.isTitleConfident = false // Fallback is marked uncertain
                    break
                }
            }
        }

        // 5. Candidate Instructions: remaining body text
        let instructionLines = lines.filter { line in
            line != candidate.candidateTitle &&
            line != candidate.candidateSubject &&
            line != candidate.candidateTeacher
        }
        if !instructionLines.isEmpty {
            candidate.candidateInstructions = instructionLines.joined(separator: "\n")
        }

        return candidate
    }
}
