//
//  WhatIfGradeCalculatorView.swift
//  StudyOS
//

import SwiftUI

/// What-If Grade Calculator: projects the final course grade after a
/// hypothetical score on the remaining (ungraded) portion of the course.
public struct WhatIfGradeCalculatorView: View {
    @State private var currentGrade: Double = 84
    @State private var completedWeight: Double = 55
    @State private var remainingWeight: Double = 45
    @State private var hypothesizedScore: Double = 90

    public init() {}

    private var projectedGrade: Double? {
        StudentCalculators.calculateWhatIfGrade(
            currentGradePercentage: currentGrade,
            completedWeightPercentage: completedWeight,
            remainingWeightPercentage: remainingWeight,
            hypothesizedRemainingScorePercentage: hypothesizedScore
        )
    }

    public var body: some View {
        Form {
            Section {
                LabeledRow(label: "Current grade", value: percentText(currentGrade))
                Slider(value: $currentGrade, in: 0...100, step: 1) {
                    Text("Current grade")
                } minimumValueLabel: {
                    Text("0%").font(.caption2)
                } maximumValueLabel: {
                    Text("100%").font(.caption2)
                }
                .accessibilityValue(Text(percentText(currentGrade)))
            } header: {
                Text("Where You Are")
            } footer: {
                Text("Your grade from graded work so far, and how much of the course that work covered.")
            }

            Section {
                LabeledRow(label: "Remaining coursework", value: percentText(remainingWeight))
                Slider(value: $remainingWeight, in: 1...100, step: 1) {
                    Text("Remaining coursework")
                } minimumValueLabel: {
                    Text("1%").font(.caption2)
                } maximumValueLabel: {
                    Text("100%").font(.caption2)
                }
                .accessibilityValue(Text(percentText(remainingWeight)))

                if abs((completedWeight + remainingWeight) - 100) > 0.5 {
                    Text("Completed (\(percentText(completedWeight))) + remaining (\(percentText(remainingWeight))) totals \(percentText(completedWeight + remainingWeight)). Grades are normalized, but 100% is typical.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("What's Left")
            }

            Section {
                LabeledRow(label: "Score on remaining work", value: percentText(hypothesizedScore))
                Slider(value: $hypothesizedScore, in: 0...100, step: 1) {
                    Text("Score on remaining work")
                } minimumValueLabel: {
                    Text("0%").font(.caption2)
                } maximumValueLabel: {
                    Text("100%").font(.caption2)
                }
                .accessibilityValue(Text(percentText(hypothesizedScore)))
            } header: {
                Text("Your Hypothesis")
            }

            if let projected = projectedGrade {
                let (letter, gpa) = StudentCalculators.letterGradeAndPoint(for: projected)
                Section("Projected Final Grade") {
                    VStack(alignment: .center, spacing: 4) {
                        Text(percentText(projected))
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundStyle(Color.accentColor)

                        Text("\(letter) • \(String(format: "%.1f", gpa)) GPA point")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("Projected final grade \(percentText(projected)), letter \(letter)"))
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .dismissibleKeyboard()
        .navigationTitle("What-If Grade")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func percentText(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }
}

private struct LabeledRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .font(.subheadline)
    }
}
