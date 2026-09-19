//
//  GradeCalculatorView.swift
//  StudyOS
//

import SwiftUI

public struct GradeCalculatorView: View {
    @State private var currentGradeText: String = "88"
    @State private var currentWeightText: String = "80"
    @State private var targetGradeText: String = "90"

    public init() {}

    private var requiredFinalGrade: Double? {
        guard let cur = Double(currentGradeText),
              let weight = Double(currentWeightText),
              let target = Double(targetGradeText) else { return nil }
        return StudentCalculators.calculateRequiredFinalGrade(
            currentGradePercentage: cur,
            currentWeightPercentage: weight,
            desiredFinalGradePercentage: target
        )
    }

    public var body: some View {
        Form {
            Section {
                HStack {
                    Text("Current Grade")
                    Spacer()
                    TextField("88", text: $currentGradeText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("%")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Current Course Weight")
                    Spacer()
                    TextField("80", text: $currentWeightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("%")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Current Standing")
            } footer: {
                let finalWeight = 100.0 - (Double(currentWeightText) ?? 0.0)
                Text("The final exam will account for \(String(format: "%.1f", max(0, finalWeight)))% of your total grade.")
            }

            Section("Target Goal") {
                HStack {
                    Text("Desired Final Grade")
                    Spacer()
                    TextField("90", text: $targetGradeText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("%")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Result") {
                if let req = requiredFinalGrade {
                    VStack(alignment: .center, spacing: 6) {
                        Text("\(String(format: "%.1f", req))%")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundStyle(req > 100.0 ? .red : (req <= 70 ? .green : .blue))

                        Text(resultAdvice(requiredPercentage: req))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } else {
                    Text("Enter your current grade and target percentage to calculate the required exam score.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .dismissibleKeyboard()
        .navigationTitle("Final Exam Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func resultAdvice(requiredPercentage: Double) -> String {
        if requiredPercentage > 100.0 {
            return "You need over 100% on the final. Consider asking for extra credit."
        } else if requiredPercentage <= 60.0 {
            return "Comfortable target. A passing score on the final achieves your goal."
        } else {
            return "Achievable with dedicated review."
        }
    }
}
