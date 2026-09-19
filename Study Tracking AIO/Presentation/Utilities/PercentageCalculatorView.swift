//
//  PercentageCalculatorView.swift
//  StudyOS
//

import SwiftUI

public struct PercentageCalculatorView: View {
    @State private var mode: StudentCalculators.PercentageMode = .percentageOfValue

    // Inputs
    @State private var input1: String = "15"
    @State private var input2: String = "120"

    public init() {}

    private var calculationResult: String {
        guard let val1 = Double(input1), let val2 = Double(input2) else {
            return "Enter numbers above"
        }

        switch mode {
        case .percentageOfValue:
            let res = StudentCalculators.calculatePercentageOfValue(percentage: val1, value: val2)
            return "\(String(format: "%.2f", val1))% of \(String(format: "%.2f", val2)) = \(String(format: "%.2f", res))"
        case .valueIsWhatPercent:
            if let pct = StudentCalculators.calculateWhatPercent(part: val1, total: val2) {
                return "\(String(format: "%.2f", val1)) is \(String(format: "%.2f", pct))% of \(String(format: "%.2f", val2))"
            } else {
                return "Total cannot be zero"
            }
        case .percentageChange:
            if let change = StudentCalculators.calculatePercentChange(from: val1, to: val2) {
                let sign = change >= 0 ? "+" : ""
                return "\(sign)\(String(format: "%.2f", change))% change"
            } else {
                return "Initial value cannot be zero"
            }
        }
    }

    public var body: some View {
        Form {
            Section {
                Picker("Calculation Type", selection: $mode) {
                    ForEach(StudentCalculators.PercentageMode.allCases, id: \.self) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
            }

            Section("Inputs") {
                HStack {
                    Text(input1Label)
                    Spacer()
                    TextField("0", text: $input1)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text(input2Label)
                    Spacer()
                    TextField("0", text: $input2)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section("Result") {
                Text(calculationResult)
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .dismissibleKeyboard()
        .navigationTitle("Percentage Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var input1Label: String {
        switch mode {
        case .percentageOfValue: return "Percentage (%)"
        case .valueIsWhatPercent: return "Part (X)"
        case .percentageChange: return "Initial Value (X)"
        }
    }

    private var input2Label: String {
        switch mode {
        case .percentageOfValue: return "Total Value (Y)"
        case .valueIsWhatPercent: return "Total (Y)"
        case .percentageChange: return "Final Value (Y)"
        }
    }
}
