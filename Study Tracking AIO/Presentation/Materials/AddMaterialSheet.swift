//
//  AddMaterialSheet.swift
//  StudyOS
//

import SwiftUI
import SwiftData
import PhotosUI

public struct AddMaterialSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var materialType: MaterialFileType = .note
    @State private var title: String = ""
    @State private var subject: String = ""
    @State private var noteContent: String = ""
    @State private var tagsString: String = ""

    // Photo/file selection
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section("Type & Info") {
                    Picker("Material Type", selection: $materialType) {
                        ForEach(MaterialFileType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.systemImage).tag(type)
                        }
                    }

                    TextField("Title", text: $title)
                        .accessibilityIdentifier("material.title")
                    TextField("Subject / Class", text: $subject)
                        .accessibilityIdentifier("material.subject")
                }

                if materialType == .note || materialType == .worksheet {
                    Section("Note Content / Text") {
                        TextField("Type or paste study notes, formulas, vocabulary...", text: $noteContent, axis: .vertical)
                            .lineLimit(6...14)
                    }
                } else if materialType == .image || materialType == .scan {
                    Section("Attach Image") {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label(
                                selectedImageData == nil ? "Select Photo / Scan" : "Change Selected Image",
                                systemImage: "photo"
                            )
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                    if let image = PlatformImage(data: data), let cgImage = image.cgImageOrNil {
                                        // Run on-device OCR text extraction for searchability!
                                        let text = try? await DocumentScannerService.shared.recognizeText(from: cgImage)
                                        if let text = text, !text.isEmpty {
                                            noteContent = text
                                        }
                                    }
                                }
                            }
                        }

                        if selectedImageData != nil {
                            Label("Image attached and ready", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
                }

                Section("Tags") {
                    TextField("Comma separated (e.g. Unit 3, Exam Prep)", text: $tagsString)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissibleKeyboard()
            .navigationTitle("New Material")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveMaterial() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || subject.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityIdentifier("material.save")
                }
            }
        }
    }

    private func saveMaterial() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = tagsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }

        var savedFileRef: String? = nil
        if let imgData = selectedImageData {
            savedFileRef = try? LocalStorageManager.shared.saveFile(data: imgData, suggestedFileName: "\(cleanTitle).jpg")
        }

        let material = Material(
            title: cleanTitle,
            subject: cleanSubject,
            localFileReference: savedFileRef,
            extractedTextReference: noteContent.isEmpty ? nil : noteContent,
            fileType: materialType,
            tags: tags
        )
        modelContext.insert(material)
        SpotlightIndexer.shared.indexMaterial(material)
        try? modelContext.save()
        dismiss()
    }
}
