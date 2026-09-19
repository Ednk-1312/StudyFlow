//
//  MaterialsListView.swift
//  StudyOS
//

import SwiftUI
import SwiftData

public struct MaterialsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Material.createdAt, order: .reverse) private var materials: [Material]

    @State private var searchText: String = ""
    @State private var selectedFileType: MaterialFileType? = nil
    @State private var isAddSheetPresented: Bool = false

    public init() {}

    private var filteredMaterials: [Material] {
        materials.filter { material in
            if let selected = selectedFileType, material.fileType != selected {
                return false
            }
            if !searchText.isEmpty {
                let matchTitle = material.title.localizedCaseInsensitiveContains(searchText)
                let matchSubject = material.subject.localizedCaseInsensitiveContains(searchText)
                let matchText = material.extractedTextReference?.localizedCaseInsensitiveContains(searchText) ?? false
                let matchTag = material.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
                return matchTitle || matchSubject || matchText || matchTag
            }
            return true
        }
    }

    public var body: some View {
        NavigationStack {
            Group {
                if materials.isEmpty {
                    StudyOSEmptyState(
                        title: "No Materials Yet",
                        systemImage: "folder",
                        description: "Store school notes, PDFs, worksheets, and syllabus documents locally on device.",
                        actionTitle: "Add Material",
                        action: { isAddSheetPresented = true }
                    )
                } else if filteredMaterials.isEmpty {
                    StudyOSEmptyState(
                        title: "No Matching Materials",
                        systemImage: "magnifyingglass",
                        description: "No materials match your current search or filter."
                    )
                } else {
                    List {
                        ForEach(filteredMaterials) { material in
                            NavigationLink(destination: MaterialDetailView(material: material)) {
                                HStack(alignment: .center, spacing: 12) {
                                    Image(systemName: material.fileType.systemImage)
                                        .font(.title3)
                                        .foregroundStyle(.tint)
                                        .frame(width: 32)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(material.title)
                                            .font(.body.weight(.medium))

                                        HStack(spacing: 6) {
                                            SubjectTag(subject: material.subject)
                                            Text("•")
                                                .foregroundStyle(.tertiary)
                                            Text(material.fileType.rawValue)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Materials & Notes")
            .searchable(text: $searchText, prompt: "Search documents, notes, tags")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("All Types") {
                            selectedFileType = nil
                        }
                        Divider()
                        ForEach(MaterialFileType.allCases, id: \.self) { type in
                            Button(type.rawValue) {
                                selectedFileType = type
                            }
                        }
                    } label: {
                        Label(
                            selectedFileType?.rawValue ?? "Filter",
                            systemImage: selectedFileType == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill"
                        )
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddSheetPresented = true
                    } label: {
                        Label("Add Material", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddSheetPresented) {
                AddMaterialSheet()
            }
        }
    }
}
