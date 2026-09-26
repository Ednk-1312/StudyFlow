//
//  CameraScanView.swift
//  StudyOS
//

// Camera capture relies on UIImagePickerController, which is iOS-only.
// macOS uses photo-library import and file import instead.
#if canImport(UIKit)

import SwiftUI
import UIKit
import AVFoundation

/// Full-screen camera capture for photographing a worksheet or assignment sheet.
/// Uses UIImagePickerController in photo mode, which works reliably across devices.
/// Presents an explanatory pre-permission screen first, and a simulator fallback.
struct CameraCaptureView: UIViewControllerRepresentable {
    var onImageCaptured: (UIImage) -> Void
    var onCancelled: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCaptureView

        init(parent: CameraCaptureView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            } else {
                parent.onCancelled()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancelled()
        }
    }
}

/// Wrapped camera entry point that checks authorization, shows a pre-permission
/// explanation, and surfaces a clear state when the camera is unavailable
/// (denied permission, no camera hardware, or Simulator).
struct CameraScanFlow: View {
    @Environment(\.dismiss) private var dismiss

    enum Phase {
        case explanation
        case denied
        case unavailable
        case capture
    }

    @State private var phase: Phase = .explanation

    var onImageCaptured: (UIImage) -> Void

    var body: some View {
        Group {
            switch phase {
            case .explanation:
                explanationView
            case .capture:
                CameraCaptureView(
                    onImageCaptured: { image in
                        onImageCaptured(image)
                        dismiss()
                    },
                    onCancelled: { dismiss() }
                )
                .ignoresSafeArea()
            case .denied:
                deniedView
            case .unavailable:
                unavailableView
            }
        }
    }

    private var explanationView: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Photograph a worksheet")
                        .font(.headline)
                    Text("StudyOS will read the text on the page with on-device text recognition and fill in fields for you to review before saving. The photo and the extracted text stay on this device.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            Section {
                Button {
                    requestCameraAndCapture()
                } label: {
                    Label("Open Camera", systemImage: "camera")
                }
            }
        }
        .navigationTitle("Scan")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var deniedView: some View {
        ContentUnavailableView {
            Label("Camera Access Off", systemImage: "camera.badge.ellipsis")
        } description: {
            Text("Allow camera access in Settings to photograph worksheets, or pick a photo from your library instead.")
        } actions: {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
        }
    }

    private var unavailableView: some View {
        ContentUnavailableView {
            Label("No Camera Available", systemImage: "camera.on.rectangle")
        } description: {
            Text("This device has no camera. Choose a photo from your library instead.")
        }
    }

    private func requestCameraAndCapture() {
        // Simulator and camera-less devices: UIImagePickerController with .camera
        // source crashes, so check availability first.
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            phase = .unavailable
            return
        }
        AVCaptureDevice.requestAccess(for: .video) { granted in
            Task { @MainActor in
                if granted {
                    phase = .capture
                } else {
                    phase = .denied
                }
            }
        }
    }
}

#endif // canImport(UIKit)
