//
//  DocumentScannerService.swift
//  StudyOS
//

import Foundation
import Vision
#if canImport(UIKit)
import UIKit
#endif

public protocol DocumentScannerProtocol: Sendable {
    func recognizeText(from cgImage: CGImage) async throws -> String
    func extractAssignment(from cgImage: CGImage) async throws -> ExtractedAssignmentCandidate
}

public final class DocumentScannerService: DocumentScannerProtocol, Sendable {
    public static let shared = DocumentScannerService()

    private let extractor: ScannedAssignmentExtractor

    public init(extractor: ScannedAssignmentExtractor = .shared) {
        self.extractor = extractor
    }

    public func recognizeText(from cgImage: CGImage) async throws -> String {
        // Vision's accurate recognition is CPU-heavy; keep it off the main actor.
        let image = cgImage
        return try await Task.detached(priority: .userInitiated) {
            try Self.performRecognition(on: image)
        }.value
    }

    /// Runs accurate text recognition. Deliberately nonisolated and off the
    /// main actor: Vision request execution is CPU-bound.
    private nonisolated static func performRecognition(on cgImage: CGImage) throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        let observations = request.results ?? []
        return observations
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }

    public func extractAssignment(from cgImage: CGImage) async throws -> ExtractedAssignmentCandidate {
        let rawText = try await recognizeText(from: cgImage)
        return extractor.extractCandidate(from: rawText)
    }

    #if canImport(UIKit)
    public func recognizeText(from uiImage: UIImage) async throws -> String {
        guard let cgImage = uiImage.cgImage else {
            throw NSError(domain: "DocumentScannerService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image format"])
        }
        return try await recognizeText(from: cgImage)
    }

    public func extractAssignment(from uiImage: UIImage) async throws -> ExtractedAssignmentCandidate {
        guard let cgImage = uiImage.cgImage else {
            throw NSError(domain: "DocumentScannerService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image format"])
        }
        return try await extractAssignment(from: cgImage)
    }
    #endif
}
