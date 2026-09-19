//
//  LocalStorageManager.swift
//  StudyOS
//

import Foundation

public protocol LocalStorageManaging {
    func saveFile(data: Data, suggestedFileName: String) throws -> String
    func readFile(relativeFileName: String) throws -> Data
    func deleteFile(relativeFileName: String) throws
    func fileExists(relativeFileName: String) -> Bool
    func totalStorageUsageBytes() -> Int64
    func getFileUrl(relativeFileName: String) -> URL
}

public final class LocalStorageManager: LocalStorageManaging {
    public static let shared = LocalStorageManager()

    private let documentsDirectory: URL
    private let materialsDirectory: URL

    public init(fileManager: FileManager = .default) {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.documentsDirectory = docs
        self.materialsDirectory = docs.appendingPathComponent("StudyOSMaterials", isDirectory: true)

        if !fileManager.fileExists(atPath: materialsDirectory.path) {
            try? fileManager.createDirectory(at: materialsDirectory, withIntermediateDirectories: true)
        }
    }

    public func saveFile(data: Data, suggestedFileName: String) throws -> String {
        let sanitized = sanitizeFileName(suggestedFileName)
        let uniqueName = "\(UUID().uuidString.prefix(8))_\(sanitized)"
        let targetUrl = materialsDirectory.appendingPathComponent(uniqueName)
        try data.write(to: targetUrl, options: .atomic)
        return uniqueName
    }

    public func readFile(relativeFileName: String) throws -> Data {
        let fileUrl = materialsDirectory.appendingPathComponent(relativeFileName)
        return try Data(contentsOf: fileUrl)
    }

    public func deleteFile(relativeFileName: String) throws {
        let fileUrl = materialsDirectory.appendingPathComponent(relativeFileName)
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            try FileManager.default.removeItem(at: fileUrl)
        }
    }

    public func fileExists(relativeFileName: String) -> Bool {
        let fileUrl = materialsDirectory.appendingPathComponent(relativeFileName)
        return FileManager.default.fileExists(atPath: fileUrl.path)
    }

    public func getFileUrl(relativeFileName: String) -> URL {
        materialsDirectory.appendingPathComponent(relativeFileName)
    }

    public func totalStorageUsageBytes() -> Int64 {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: materialsDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        var total: Int64 = 0
        for file in files {
            if let resources = try? file.resourceValues(forKeys: [.fileSizeKey]),
               let size = resources.fileSize {
                total += Int64(size)
            }
        }
        return total
    }

    private func sanitizeFileName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>| \n\r\t")
        let components = name.components(separatedBy: invalidCharacters)
        let clean = components.filter { !$0.isEmpty }.joined(separator: "_")
        return clean.isEmpty ? "document.dat" : clean
    }
}
