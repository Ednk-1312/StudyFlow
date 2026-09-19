//
//  UnitConverterView.swift
//  StudyOS
//

import SwiftUI

public struct UnitConverterView: View {
    @State private var category: StudentCalculators.UnitCategory = .length
    @State private var inputValue: String = "10"
    @State private var fromUnit: String = "Meters"
    @State private var toUnit: String = "Feet"

    public init() {}

    private var availableUnits: [String] {
        switch category {
        case .length:
            return ["Meters", "Kilometers", "Centimeters", "Millimeters", "Inches", "Feet", "Miles"]
        case .mass:
            return ["Grams", "Kilograms", "Milligrams", "Pounds", "Ounces"]
        case .time:
            return ["Seconds", "Minutes", "Hours", "Days", "Weeks"]
        case .temperature:
            return ["Celsius", "Fahrenheit", "Kelvin"]
        case .digital:
            return ["Bytes", "Kilobytes (KB)", "Megabytes (MB)", "Gigabytes (GB)", "Terabytes (TB)"]
        }
    }

    private var convertedValue: String {
        guard let val = Double(inputValue) else { return "—" }
        if let res = StudentCalculators.convert(value: val, from: fromUnit, to: toUnit, category: category) {
            return String(format: "%.4g", res)
        }
        return "—"
    }

    public var body: some View {
        Form {
            Section {
                Picker("Category", selection: $category) {
                    ForEach(StudentCalculators.UnitCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                .onChange(of: category) { _, newCat in
                    let units = availableUnits
                    fromUnit = units.first ?? ""
                    toUnit = units.count > 1 ? units[1] : units.first ?? ""
                }
            }

            Section("Conversion") {
                HStack {
                    TextField("Value", text: $inputValue)
                        .keyboardType(.decimalPad)
                    Spacer()
                    Picker("From", selection: $fromUnit) {
                        ForEach(availableUnits, id: \.self) { u in
                            Text(u).tag(u)
                        }
                    }
                    .pickerStyle(.menu)
                }

                HStack {
                    Text(convertedValue)
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                    Spacer()
                    Picker("To", selection: $toUnit) {
                        ForEach(availableUnits, id: \.self) { u in
                            Text(u).tag(u)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .dismissibleKeyboard()
        .navigationTitle("Unit Converter")
        .navigationBarTitleDisplayMode(.inline)
    }
}
