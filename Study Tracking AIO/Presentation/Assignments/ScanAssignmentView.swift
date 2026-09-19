//
//  ScanAssignmentView.swift
//  StudyOS
//

import SwiftUI
import SwiftData
import PhotosUI

public struct ScanAssignmentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var scanStep: ScanStep = .selectSource
    @State private var isProcessing: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var rawText: String = ""
    @State private var isCameraPresented: Bool = false
    @State private var failureMessage: String? = nil

    // Candidate Extracted Fields
    @State private var candidateTitle: String = ""
    @State private var isTitleConfident: Bool = true
    @State private var candidateSubject: String = ""
    @State private var isSubjectConfident: Bool = true
    @State private var candidateDueDate: Date = Date().addingTimeInterval(86400)
    @State private var hasExtractedDueDate: Bool = false
    @State private var isDueDateConfident: Bool = true
    @State private var candidateTeacher: String = ""
    @State private var candidateInstructions: String = ""
    @State private var estimatedMinutes: Int = 45
    @State private var priority: AssignmentPriority = .medium

    public enum ScanStep {
        case selectSource
        case confirmExtraction
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                switch scanStep {
                case .selectSource:
                    sourceSelectionView
                case .confirmExtraction:
                    confirmationFormView
                }
            }
            .navigationTitle(scanStep == .selectSource ? "Scan Assignment" : "Confirm Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                if scanStep == .confirmExtraction {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save Assignment") {
                            saveExtractedAssignment()
                        }
                        .disabled(candidateTitle.trimmingCharacters(in: .whitespaces).isEmpty || candidateSubject.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }

    // MARK: - Step 1: Source Selection
    private var sourceSelectionView: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Capture or Import Worksheet")
                        .font(.headline)
                    Text("Select a photo of a syllabus, assignment rubric, or worksheet. On-device Vision OCR will extract candidate titles, dates, and instructions for you to review.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Select Image") {
                Button {
                    isCameraPresented = true
                } label: {
                    Label("Take Photo", systemImage: "camera")
                }

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Choose from Photo Library", systemImage: "photo.on.rectangle")
                }
                .onChange(of: selectedPhotoItem) {
                    Task {
                        await processPickedItem(selectedPhotoItem)
                    }
                }
            }

            if isProcessing {
                Section {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Reading text on this device…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            if let failureMessage {
                Section {
                    Label(failureMessage, systemImage: "exclamationmark.triangle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraScanFlow { image in
                processImage(image)
            }
        }
    }

    // MARK: - Step 2: Confirmation & Edit
    private var confirmationFormView: some View {
        Form {
            Section {
                Text("Review the extracted details before saving. Tap any field to correct it.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Title")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if !isTitleConfident {
                            Spacer()
                            Label("Uncertain title", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                    TextField("Title", text: $candidateTitle)
                        .font(.body.weight(.medium))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Subject / Class")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if !isSubjectConfident {
                            Spacer()
                            Label("Uncertain subject", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                    TextField("Subject", text: $candidateSubject)
                }

                if !candidateTeacher.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Teacher")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Teacher", text: $candidateTeacher)
                    }
                }
            } header: {
                Text("Assignment Info")
            }

            Section {
                DatePicker("Due Date", selection: $candidateDueDate, displayedComponents: [.date, .hourAndMinute])

                if !hasExtractedDueDate {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("No due date found in scan. Please enter the due date manually.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if !isDueDateConfident {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Due date wasn't labeled with high certainty. Please verify.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Stepper("Estimated Effort: \(estimatedMinutes) min", value: $estimatedMinutes, in: 5...360, step: 15)

                Picker("Priority", selection: $priority) {
                    ForEach(AssignmentPriority.allCases, id: \.self) { p in
                        Label(p.rawValue, systemImage: StudyOSTheme.priorityIcon(for: p)).tag(p)
                    }
                }
            } header: {
                Text("Schedule")
            }

            Section("Instructions & Notes") {
                TextField("Instructions", text: $candidateInstructions, axis: .vertical)
                    .lineLimit(3...8)
            }

            if !rawText.isEmpty {
                Section("Raw Recognized Text") {
                    Text(rawText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(6)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .dismissibleKeyboard()
    }

    private func processPickedItem(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        isProcessing = true
        defer { isProcessing = false }

        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            processImage(uiImage)
        } else {
            failureMessage = "Couldn't load that photo. Try a different image."
        }
    }

    private func processImage(_ uiImage: UIImage) {
        isProcessing = true
        Task {
            do {
                let candidate = try await DocumentScannerService.shared.extractAssignment(from: uiImage)
                let foundText = !candidate.rawRecognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                await MainActor.run {
                    if foundText {
                        applyCandidate(candidate)
                        scanStep = .confirmExtraction
                    } else {
                        failureMessage = "No readable text was found in this image. Try a closer, well-lit photo, or enter the details manually."
                    }
                }
            } catch {
                await MainActor.run {
                    failureMessage = "Text recognition failed. Try a different photo, or add the assignment manually."
                }
            }
            await MainActor.run {
                isProcessing = false
                selectedPhotoItem = nil
            }
        }
    }

    private func applyCandidate(_ candidate: ExtractedAssignmentCandidate) {
        self.rawText = candidate.rawRecognizedText
        self.candidateTitle = candidate.candidateTitle ?? "New Assignment"
        self.isTitleConfident = candidate.isTitleConfident
        self.candidateSubject = candidate.candidateSubject ?? ""
        self.isSubjectConfident = candidate.isSubjectConfident
        self.candidateTeacher = candidate.candidateTeacher ?? ""
        self.candidateInstructions = candidate.candidateInstructions ?? ""

        if let due = candidate.candidateDueDate {
            self.candidateDueDate = due
            self.hasExtractedDueDate = true
            self.isDueDateConfident = candidate.isDueDateConfident
        } else {
            self.candidateDueDate = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
            self.hasExtractedDueDate = false
            self.isDueDateConfident = false
        }

        self.scanStep = .confirmExtraction
    }

    private func saveExtractedAssignment() {
        let cleanTitle = candidateTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSubject = candidateSubject.trimmingCharacters(in: .whitespacesAndNewlines)

        let notes = candidateTeacher.isEmpty
            ? candidateInstructions
            : "Teacher: \(candidateTeacher)\n\n\(candidateInstructions)"

        let assignment = Assignment(
            title: cleanTitle,
            subject: cleanSubject,
            courseName: cleanSubject,
            dueDate: candidateDueDate,
            estimatedMinutes: estimatedMinutes,
            priority: priority,
            status: .notStarted,
            notes: notes,
            source: .cameraScan
        )
        AssignmentStore.shared.saveNew(assignment, in: modelContext)

        try? modelContext.saveOrThrow()
        dismiss()
    }
}
