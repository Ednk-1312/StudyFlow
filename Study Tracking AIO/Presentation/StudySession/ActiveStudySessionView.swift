//
//  ActiveStudySessionView.swift
//  StudyOS
//

import SwiftUI
import SwiftData
import Combine
import WidgetKit

public struct ActiveStudySessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    public let assignment: Assignment?
    public let initialDurationMinutes: Int

    @State private var remainingSeconds: Int
    @State private var totalDurationSeconds: Int
    @State private var isRunning: Bool = false
    @State private var isBreakMode: Bool = false
    @State private var interruptionsCount: Int = 0
    @State private var sessionNotes: String = ""
    @State private var elapsedActiveSeconds: Int = 0
    @State private var elapsedBreakSeconds: Int = 0

    @State private var isCompletionSheetPresented: Bool = false
    @State private var sessionModel: StudySession?

    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    public init(assignment: Assignment? = nil, initialDurationMinutes: Int = 25) {
        self.assignment = assignment
        self.initialDurationMinutes = initialDurationMinutes
        _remainingSeconds = State(initialValue: initialDurationMinutes * 60)
        _totalDurationSeconds = State(initialValue: initialDurationMinutes * 60)
    }

    private var progress: Double {
        guard totalDurationSeconds > 0 else { return 0 }
        let elapsed = totalDurationSeconds - remainingSeconds
        return Double(elapsed) / Double(totalDurationSeconds)
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Target header
                VStack(spacing: 4) {
                    if let assignment = assignment {
                        SubjectTag(subject: assignment.courseName)
                        Text(assignment.title)
                            .font(.headline)
                            .lineLimit(1)
                    } else {
                        Text("General Study Session")
                            .font(.headline)
                    }

                    Text(isBreakMode ? "Rest Break" : "Focus Time")
                        .font(.subheadline)
                        .foregroundStyle(isBreakMode ? .green : .secondary)
                }
                .padding(.top, 16)

                Spacer()

                // Circular Timer Display
                ZStack {
                    Circle()
                        .stroke(Color(uiColor: .tertiarySystemFill), lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            isBreakMode ? Color.green : Color.accentColor,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: progress)

                    VStack(spacing: 6) {
                        Text(formattedTime(remainingSeconds))
                            .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                            .monospacedDigit()
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .accessibilityLabel("\(remainingSeconds / 60) minutes and \(remainingSeconds % 60) seconds remaining")

                        if interruptionsCount > 0 {
                            Label("\(interruptionsCount) interruptions", systemImage: "bolt.badge.clock")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(width: 260, height: 260)

                Spacer()

                // Control Buttons
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        // Log Interruption
                        Button {
                            Haptics.warning()
                            interruptionsCount += 1
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "bolt.badge.clock")
                                    .font(.title3)
                                Text("Distraction")
                                    .font(.caption2)
                            }
                            .frame(minWidth: 72, minHeight: 56)
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondary)

                        // Play / Pause (Primary Action)
                        Button {
                            Haptics.tap()
                            isRunning.toggle()
                        } label: {
                            Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                .font(.title)
                                .frame(width: 80, height: 80)
                        }
                        .buttonStyle(.borderedProminent)
                        .clipShape(Circle())
                        .tint(isBreakMode ? .green : .accentColor)
                        .accessibilityLabel(isRunning ? "Pause" : "Play")
                        .accessibilityIdentifier("session.playPause")

                        // Add 5 Minutes
                        Button {
                            Haptics.tap()
                            remainingSeconds += 300
                            totalDurationSeconds += 300
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "plus.circle")
                                    .font(.title3)
                                Text("+5 min")
                                    .font(.caption2)
                            }
                            .frame(minWidth: 72, minHeight: 56)
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                    }

                    // Mode Toggle: Break vs Focus
                    Button {
                        Haptics.selection()
                        toggleBreakMode()
                    } label: {
                        Label(
                            isBreakMode ? "Resume Focus Session" : "Switch to 5-min Break",
                            systemImage: isBreakMode ? "brain.head.profile" : "cup.and.saucer"
                        )
                        .font(.subheadline)
                    }
                    .buttonStyle(.borderless)
                    .tint(.secondary)
                    .accessibilityIdentifier("session.break")
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Study Timer")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // Session start updates the widget "Studying" card.
                WidgetSnapshotWriter.reload(context: modelContext)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("End Session") {
                        completeSession()
                    }
                }
            }
            .onReceive(timer) { _ in
                guard isRunning else { return }
                if remainingSeconds > 0 {
                    remainingSeconds -= 1
                    if isBreakMode {
                        elapsedBreakSeconds += 1
                    } else {
                        elapsedActiveSeconds += 1
                    }
                } else {
                    isRunning = false
                    completeSession()
                }
            }
            .sheet(isPresented: $isCompletionSheetPresented) {
                SessionCompletionSheet(
                    assignment: assignment,
                    durationStudiedMinutes: max(1, elapsedActiveSeconds / 60),
                    onContinueSession: {
                        remainingSeconds = 15 * 60
                        totalDurationSeconds = 15 * 60
                        isRunning = true
                    },
                    onFinishSession: {
                        dismiss()
                    }
                )
            }
        }
    }

    private func formattedTime(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func toggleBreakMode() {
        if isBreakMode {
            // Return to focus
            isBreakMode = false
            remainingSeconds = 25 * 60
            totalDurationSeconds = 25 * 60
        } else {
            // Switch to break
            isBreakMode = true
            remainingSeconds = 5 * 60
            totalDurationSeconds = 5 * 60
        }
    }

    private func completeSession() {
        let session = StudySession(
            assignmentID: assignment?.id,
            subject: assignment?.courseName ?? "General Study",
            plannedStart: Date().addingTimeInterval(-Double(elapsedActiveSeconds + elapsedBreakSeconds)),
            plannedDuration: Double(initialDurationMinutes * 60),
            actualDuration: Double(elapsedActiveSeconds),
            status: .completed,
            notes: sessionNotes,
            breaksDuration: Double(elapsedBreakSeconds),
            interruptionsCount: interruptionsCount,
            completedAt: Date()
        )
        modelContext.insert(session)
        do {
            try modelContext.saveOrThrow()
        } catch {
            AppState.shared.dataErrorMessage = "Your session notes may not be saved. " + error.localizedDescription
        }
        WidgetSnapshotWriter.reload(context: modelContext)

        Haptics.success()
        isCompletionSheetPresented = true
    }
}
