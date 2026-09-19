//
//  WeightedGradeCalculatorView.swift
//  StudyOS
//

import SwiftUI

public struct WeightedGradeCalculatorView: View {
    @State private var categories: [StudentCalculators.WeightedCategory] = [
        .init(name: "Homework", scorePercentage: 92, weightPercentage: 20),
        .init(name: "Quizzes", scorePercentage: 85, weightPercentage: 25),
        .init(name: "Midterm Exam", scorePercentage: 78, weightPercentage: 25),
        .init(name: "Final Project", scorePercentage: 90, weightPercentage: 30)
    ]

    public init() {}

    private var calculatedResult: (grade: Double, totalWeight: Double)? {
        StudentCalculators.calculateWeightedGrade(categories: categories)
    }

    public var body: some View {
        Form {
            Section {
                ForEach($categories) { $cat in
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Category Name", text: $cat.name)
                            .font(.body.weight(.medium))

                        HStack(spacing: 12) {
                            HStack {
                                Text("Score:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("90", value: $cat.scorePercentage, format: .number)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                Text("%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            HStack {
                                Text("Weight:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("25", value: $cat.weightPercentage, format: .number)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                Text("%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onDelete { indices in
                    categories.remove(atOffsets: indices)
                }

                Button {
                    categories.append(.init(name: "New Category", scorePercentage: 85, weightPercentage: 10))
                } label: {
                    Label("Add Grade Category", systemImage: "plus")
                }
            } header: {
                Text("Course Categories")
            } footer: {
                let weight = categories.reduce(0) { $0 + $1.weightPercentage }
                Text("Total Weight: \(String(format: "%.1f", weight))% \(weight == 100 ? "• 100% accounted for" : "• Needs to sum to 100%")")
                    .foregroundStyle(weight == 100 ? .green : .orange)
            }

            if let result = calculatedResult {
                Section("Calculated Weighted Grade") {
                    VStack(alignment: .center, spacing: 4) {
                        Text("\(String(format: "%.2f", result.grade))%")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundStyle(Color.accentColor)

                        let (letter, gpa) = StudentCalculators.letterGradeAndPoint(for: result.grade)
                        Text("\(letter) • \(String(format: "%.1f", gpa)) GPA Point")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .dismissibleKeyboard()
        .navigationTitle("Weighted Grade Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
}
