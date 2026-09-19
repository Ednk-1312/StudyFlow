//
//  StudentCalculators.swift
//  StudyOS
//

import Foundation

public enum StudentCalculators {

    // MARK: - 1. Grade Calculator
    public struct StandardGradeResult: Equatable {
        public let percentage: Double
        public let letterGrade: String
        public let gpaPoint: Double
    }

    public static func calculateStandardGrade(earnedPoints: Double, totalPoints: Double) -> StandardGradeResult? {
        guard totalPoints > 0 else { return nil }
        let percentage = (earnedPoints / totalPoints) * 100.0
        let (letter, point) = letterGradeAndPoint(for: percentage)
        return StandardGradeResult(percentage: percentage, letterGrade: letter, gpaPoint: point)
    }

    public static func calculateRequiredFinalGrade(
        currentGradePercentage: Double,
        currentWeightPercentage: Double,
        desiredFinalGradePercentage: Double
    ) -> Double? {
        let finalWeight = 100.0 - currentWeightPercentage
        guard finalWeight > 0 else { return nil }
        // Formula: (Desired - (Current * CurrentWeight / 100)) / (FinalWeight / 100)
        let currentContribution = currentGradePercentage * (currentWeightPercentage / 100.0)
        let neededFromFinal = desiredFinalGradePercentage - currentContribution
        let requiredFinalPercentage = neededFromFinal / (finalWeight / 100.0)
        return requiredFinalPercentage
    }

    // MARK: - 1b. What-If Grade Calculator

    /// The final course grade after a hypothetical score on remaining work.
    /// `remainingWeightPercentage` is the share of the course not yet graded.
    public static func calculateWhatIfGrade(
        currentGradePercentage: Double,
        completedWeightPercentage: Double,
        remainingWeightPercentage: Double,
        hypothesizedRemainingScorePercentage: Double
    ) -> Double? {
        guard completedWeightPercentage >= 0, remainingWeightPercentage > 0 else { return nil }
        let totalWeight = completedWeightPercentage + remainingWeightPercentage
        guard totalWeight > 0 else { return nil }
        let earned = currentGradePercentage * (completedWeightPercentage / totalWeight)
        let projected = hypothesizedRemainingScorePercentage * (remainingWeightPercentage / totalWeight)
        return earned + projected
    }

    public static func letterGradeAndPoint(for percentage: Double) -> (String, Double) {
        switch percentage {
        case 93.0...: return ("A", 4.0)
        case 90.0..<93.0: return ("A-", 3.7)
        case 87.0..<90.0: return ("B+", 3.3)
        case 83.0..<87.0: return ("B", 3.0)
        case 80.0..<83.0: return ("B-", 2.7)
        case 77.0..<80.0: return ("C+", 2.3)
        case 73.0..<77.0: return ("C", 2.0)
        case 70.0..<73.0: return ("C-", 1.7)
        case 67.0..<70.0: return ("D+", 1.3)
        case 60.0..<67.0: return ("D", 1.0)
        default: return ("F", 0.0)
        }
    }

    // MARK: - 2. Weighted Grade Calculator
    public struct WeightedCategory: Identifiable, Equatable {
        public let id: UUID
        public var name: String
        public var scorePercentage: Double
        public var weightPercentage: Double

        public init(id: UUID = UUID(), name: String, scorePercentage: Double, weightPercentage: Double) {
            self.id = id
            self.name = name
            self.scorePercentage = scorePercentage
            self.weightPercentage = weightPercentage
        }
    }

    public static func calculateWeightedGrade(categories: [WeightedCategory]) -> (grade: Double, totalWeight: Double)? {
        guard !categories.isEmpty else { return nil }
        var weightedSum = 0.0
        var totalWeight = 0.0

        for cat in categories {
            weightedSum += (cat.scorePercentage * cat.weightPercentage)
            totalWeight += cat.weightPercentage
        }

        guard totalWeight > 0 else { return nil }
        let overallGrade = weightedSum / totalWeight
        return (grade: overallGrade, totalWeight: totalWeight)
    }

    // MARK: - 3. GPA Calculator
    public struct CourseGradeItem: Identifiable, Equatable {
        public let id: UUID
        public var courseName: String
        public var letterGrade: String
        public var creditHours: Double
        public var isHonorsOrAP: Bool

        public init(id: UUID = UUID(), courseName: String, letterGrade: String, creditHours: Double = 1.0, isHonorsOrAP: Bool = false) {
            self.id = id
            self.courseName = courseName
            self.letterGrade = letterGrade
            self.creditHours = max(0.5, creditHours)
            self.isHonorsOrAP = isHonorsOrAP
        }
    }

    public struct GPAResult: Equatable {
        public let unweightedGPA: Double
        public let weightedGPA: Double
        public let totalCredits: Double
    }

    public static func calculateGPA(courses: [CourseGradeItem]) -> GPAResult? {
        guard !courses.isEmpty else { return nil }

        let gradeToUnweightedPoint: [String: Double] = [
            "A+": 4.0, "A": 4.0, "A-": 3.7,
            "B+": 3.3, "B": 3.0, "B-": 2.7,
            "C+": 2.3, "C": 2.0, "C-": 1.7,
            "D+": 1.3, "D": 1.0, "F": 0.0
        ]

        var totalCredits = 0.0
        var unweightedPoints = 0.0
        var weightedPoints = 0.0

        for course in courses {
            let basePoint = gradeToUnweightedPoint[course.letterGrade.uppercased()] ?? 0.0
            let weightedPoint = course.isHonorsOrAP ? (basePoint > 0 ? basePoint + 1.0 : 0.0) : basePoint

            unweightedPoints += (basePoint * course.creditHours)
            weightedPoints += (weightedPoint * course.creditHours)
            totalCredits += course.creditHours
        }

        guard totalCredits > 0 else { return nil }

        let unweighted = unweightedPoints / totalCredits
        let weighted = weightedPoints / totalCredits

        return GPAResult(unweightedGPA: unweighted, weightedGPA: weighted, totalCredits: totalCredits)
    }

    // MARK: - 4. Percentage Calculator
    public enum PercentageMode: String, CaseIterable {
        case percentageOfValue = "What is X% of Y?"
        case valueIsWhatPercent = "X is what % of Y?"
        case percentageChange = "% Increase / Decrease"
    }

    public static func calculatePercentageOfValue(percentage: Double, value: Double) -> Double {
        (percentage / 100.0) * value
    }

    public static func calculateWhatPercent(part: Double, total: Double) -> Double? {
        guard total != 0 else { return nil }
        return (part / total) * 100.0
    }

    public static func calculatePercentChange(from initialValue: Double, to finalValue: Double) -> Double? {
        guard initialValue != 0 else { return nil }
        return ((finalValue - initialValue) / abs(initialValue)) * 100.0
    }

    // MARK: - 5. Unit Converter
    public enum UnitCategory: String, CaseIterable {
        case length = "Length"
        case mass = "Mass"
        case time = "Time"
        case temperature = "Temperature"
        case digital = "Data Storage"
    }

    public static func convert(value: Double, from fromUnit: String, to toUnit: String, category: UnitCategory) -> Double? {
        switch category {
        case .length:
            let metersPerUnit: [String: Double] = [
                "Meters": 1.0, "Kilometers": 1000.0, "Centimeters": 0.01,
                "Millimeters": 0.001, "Inches": 0.0254, "Feet": 0.3048, "Miles": 1609.344
            ]
            guard let fromFactor = metersPerUnit[fromUnit], let toFactor = metersPerUnit[toUnit] else { return nil }
            return (value * fromFactor) / toFactor

        case .mass:
            let gramsPerUnit: [String: Double] = [
                "Grams": 1.0, "Kilograms": 1000.0, "Milligrams": 0.001,
                "Pounds": 453.592, "Ounces": 28.3495
            ]
            guard let fromFactor = gramsPerUnit[fromUnit], let toFactor = gramsPerUnit[toUnit] else { return nil }
            return (value * fromFactor) / toFactor

        case .time:
            let secondsPerUnit: [String: Double] = [
                "Seconds": 1.0, "Minutes": 60.0, "Hours": 3600.0, "Days": 86400.0, "Weeks": 604800.0
            ]
            guard let fromFactor = secondsPerUnit[fromUnit], let toFactor = secondsPerUnit[toUnit] else { return nil }
            return (value * fromFactor) / toFactor

        case .temperature:
            // Convert to Celsius first
            var celsius: Double
            if fromUnit == "Celsius" {
                celsius = value
            } else if fromUnit == "Fahrenheit" {
                celsius = (value - 32.0) * (5.0 / 9.0)
            } else if fromUnit == "Kelvin" {
                celsius = value - 273.15
            } else {
                return nil
            }

            // Convert Celsius to destination
            if toUnit == "Celsius" {
                return celsius
            } else if toUnit == "Fahrenheit" {
                return (celsius * 9.0 / 5.0) + 32.0
            } else if toUnit == "Kelvin" {
                return celsius + 273.15
            }
            return nil

        case .digital:
            let bytesPerUnit: [String: Double] = [
                "Bytes": 1.0, "Kilobytes (KB)": 1024.0, "Megabytes (MB)": 1048576.0,
                "Gigabytes (GB)": 1073741824.0, "Terabytes (TB)": 1099511627776.0
            ]
            guard let fromFactor = bytesPerUnit[fromUnit], let toFactor = bytesPerUnit[toUnit] else { return nil }
            return (value * fromFactor) / toFactor
        }
    }

    // MARK: - 6. Text Analytics
    public struct TextAnalysisResult: Equatable {
        public let characterCount: Int
        public let characterCountNoSpaces: Int
        public let wordCount: Int
        public let sentenceCount: Int
        public let readingTimeSeconds: Int
        public let speakingTimeSeconds: Int
    }

    public static func analyzeText(_ text: String) -> TextAnalysisResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let characters = text.count
        let charactersNoSpaces = text.filter { !$0.isWhitespace }.count

        let words = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let wordCount = words.count

        let sentenceSeparators = CharacterSet(charactersIn: ".!?\n")
        let rawSentences = trimmed.components(separatedBy: sentenceSeparators)
        let sentenceCount = rawSentences.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.count

        // Average reading speed: 220 words per minute; speaking speed: 130 words per minute
        let readingSeconds = Int(ceil(Double(wordCount) / (220.0 / 60.0)))
        let speakingSeconds = Int(ceil(Double(wordCount) / (130.0 / 60.0)))

        return TextAnalysisResult(
            characterCount: characters,
            characterCountNoSpaces: charactersNoSpaces,
            wordCount: wordCount,
            sentenceCount: max(wordCount > 0 ? 1 : 0, sentenceCount),
            readingTimeSeconds: readingSeconds,
            speakingTimeSeconds: speakingSeconds
        )
    }

    // MARK: - 7. Random Group Generator
    public static func generateRandomGroups(
        students: [String],
        groupCount: Int? = nil,
        groupSize: Int? = nil
    ) -> [[String]] {
        let cleanStudents = students.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.shuffled()
        guard !cleanStudents.isEmpty else { return [] }

        let targetGroupCount: Int
        if let count = groupCount, count > 0 {
            targetGroupCount = min(count, cleanStudents.count)
        } else if let size = groupSize, size > 0 {
            targetGroupCount = max(1, Int(ceil(Double(cleanStudents.count) / Double(size))))
        } else {
            targetGroupCount = max(1, cleanStudents.count / 2)
        }

        var groups: [[String]] = Array(repeating: [], count: targetGroupCount)
        for (index, student) in cleanStudents.enumerated() {
            let groupIndex = index % targetGroupCount
            groups[groupIndex].append(student)
        }

        return groups.filter { !$0.isEmpty }
    }
}
