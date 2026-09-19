//
//  UtilitiesHubView.swift
//  StudyOS
//

import SwiftUI

public struct UtilitiesHubView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("Academic Calculations") {
                    NavigationLink(destination: GradeCalculatorView()) {
                        ToolRow(
                            title: "Final Exam Calculator",
                            subtitle: "Target score needed on the final",
                            systemImage: "percent"
                        )
                    }

                    NavigationLink(destination: WhatIfGradeCalculatorView()) {
                        ToolRow(
                            title: "What-If Grade Calculator",
                            subtitle: "Project your final grade from a predicted score",
                            systemImage: "questionmark.circle"
                        )
                    }

                    NavigationLink(destination: WeightedGradeCalculatorView()) {
                        ToolRow(
                            title: "Weighted Grade Calculator",
                            subtitle: "Calculate course averages by category weights",
                            systemImage: "chart.bar.doc.horizontal"
                        )
                    }

                    NavigationLink(destination: GPACalculatorView()) {
                        ToolRow(
                            title: "GPA Calculator",
                            subtitle: "Unweighted 4.0 and weighted 5.0 scales",
                            systemImage: "graduationcap"
                        )
                    }

                    NavigationLink(destination: PercentageCalculatorView()) {
                        ToolRow(
                            title: "Percentage Calculator",
                            subtitle: "Percentages, proportions, and rate of change",
                            systemImage: "divide"
                        )
                    }
                }

                Section("Writing & Research") {
                    NavigationLink(destination: TextAnalyticsView()) {
                        ToolRow(
                            title: "Word & Character Counter",
                            subtitle: "Live word counts, reading and speaking duration",
                            systemImage: "character.cursor.ibeam"
                        )
                    }

                    NavigationLink(destination: UnitConverterView()) {
                        ToolRow(
                            title: "Unit Converter",
                            subtitle: "Length, mass, time, temperature, and data storage",
                            systemImage: "arrow.triangle.2.circlepath"
                        )
                    }
                }

                Section("Time & Organization") {
                    NavigationLink(destination: CountdownTimersView()) {
                        ToolRow(
                            title: "Exam & Assignment Countdown",
                            subtitle: "Live time remaining until upcoming deadlines",
                            systemImage: "timer"
                        )
                    }

                    NavigationLink(destination: RandomGroupGeneratorView()) {
                        ToolRow(
                            title: "Random Group Generator",
                            subtitle: "Divide class rosters into fair teams",
                            systemImage: "person.3"
                        )
                    }

                    NavigationLink(destination: SessionHistoryView()) {
                        ToolRow(
                            title: "Study Session History",
                            subtitle: "Review past study blocks, durations, and focus logs",
                            systemImage: "clock.arrow.circlepath"
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Utilities")
        }
    }
}

private struct ToolRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            // One consistent tint for every tool — icon color is not
            // used as a decorative differentiator.
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
