//
//  GPACalculatorView.swift
//  StudyOS
//

import SwiftUI

public struct GPACalculatorView: View {
    @State private var courses: [StudentCalculators.CourseGradeItem] = [
        .init(courseName: "Calculus", letterGrade: "A", creditHours: 4.0, isHonorsOrAP: true),
        .init(courseName: "Literature", letterGrade: "A-", creditHours: 3.0, isHonorsOrAP: false),
        .init(courseName: "Chemistry", letterGrade: "B+", creditHours: 4.0, isHonorsOrAP: true),
        .init(courseName: "History", letterGrade: "A", creditHours: 3.0, isHonorsOrAP: false)
    ]

    private let availableGrades = ["A+", "A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D+", "D", "F"]

    public init() {}

    private var gpaResult: StudentCalculators.GPAResult? {
        StudentCalculators.calculateGPA(courses: courses)
    }

    public var body: some View {
        Form {
            if let result = gpaResult {
                Section("GPA Summary") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Unweighted (4.0)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.2f", result.unweightedGPA))
                                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                                .foregroundStyle(Color.accentColor)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Weighted (5.0)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.2f", result.weightedGPA))
                                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.vertical, 4)

                    HStack {
                        Text("Total Credits")
                        Spacer()
                        Text(String(format: "%.1f", result.totalCredits))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Courses") {
                ForEach($courses) { $course in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            TextField("Course Name", text: $course.courseName)
                                .font(.body.weight(.medium))
                            Spacer()
                            Toggle("AP / Honors", isOn: Binding(
                                get: { course.isHonorsOrAP },
                                set: { newValue in
                                    course.isHonorsOrAP = newValue
                                    Haptics.selection()
                                }
                            ))
                            .labelsHidden()
                            Text(course.isHonorsOrAP ? "AP" : "Reg")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(course.isHonorsOrAP ? .green : .secondary)
                        }

                        HStack {
                            Picker("Grade", selection: $course.letterGrade) {
                                ForEach(availableGrades, id: \.self) { g in
                                    Text(g).tag(g)
                                }
                            }
                            .pickerStyle(.menu)

                            Spacer()

                            Stepper("\(String(format: "%.1f", course.creditHours)) Credits", value: $course.creditHours, in: 0.5...10.0, step: 0.5)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indices in
                    courses.remove(atOffsets: indices)
                }

                Button {
                    courses.append(.init(courseName: "New Course", letterGrade: "A", creditHours: 3.0, isHonorsOrAP: false))
                } label: {
                    Label("Add Course", systemImage: "plus")
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .dismissibleKeyboard()
        .navigationTitle("GPA Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
}
