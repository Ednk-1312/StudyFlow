//
//  RandomGroupGeneratorView.swift
//  StudyOS
//

import SwiftUI

public struct RandomGroupGeneratorView: View {
    @State private var rosterText: String = "Alex, Bailey, Casey, Dylan, Emma, Frank, Grace, Henry"
    @State private var splitByTeams: Bool = true
    @State private var targetCount: Int = 2
    @State private var generatedGroups: [[String]] = []

    public init() {}

    public var body: some View {
        Form {
            Section("Class Roster") {
                TextField("Enter student names (comma or new line separated)", text: $rosterText, axis: .vertical)
                    .lineLimit(4...8)
            }

            Section("Group Sizing") {
                Picker("Split Mode", selection: $splitByTeams) {
                    Text("Number of Groups").tag(true)
                    Text("Students per Group").tag(false)
                }
                .pickerStyle(.segmented)

                Stepper(
                    splitByTeams ? "Create \(targetCount) Groups" : "\(targetCount) Students / Group",
                    value: $targetCount,
                    in: 2...20
                )

                Button {
                    generate()
                } label: {
                    Label("Shuffle & Form Groups", systemImage: "shuffle")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            if !generatedGroups.isEmpty {
                Section("Generated Groups (\(generatedGroups.count))") {
                    ForEach(Array(generatedGroups.enumerated()), id: \.offset) { index, group in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Group \(index + 1) (\(group.count) students)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            Text(group.joined(separator: ", "))
                                .font(.body)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .dismissibleKeyboard()
        .navigationTitle("Group Generator")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func generate() {
        let delimiter = rosterText.contains("\n") ? "\n" : ","
        let names = rosterText.components(separatedBy: delimiter)
        if splitByTeams {
            generatedGroups = StudentCalculators.generateRandomGroups(students: names, groupCount: targetCount)
        } else {
            generatedGroups = StudentCalculators.generateRandomGroups(students: names, groupSize: targetCount)
        }
    }
}
