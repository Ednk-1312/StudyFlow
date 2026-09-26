//
//  UndoToastView.swift
//  StudyOS
//

import SwiftUI

public struct UndoToastView: View {
    public let message: String
    public let undoAction: () -> Void

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text(message)
                .font(.subheadline)
                .lineLimit(1)
            Spacer()
            Button {
                Haptics.tap()
                undoAction()
            } label: {
                Text("Undo")
                    .font(.subheadline.weight(.semibold))
            }
            .accessibilityIdentifier("toast.undo")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.platformSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.platformSeparator, lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}
