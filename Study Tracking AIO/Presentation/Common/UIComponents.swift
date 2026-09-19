//
//  UIComponents.swift
//  StudyOS
//

import SwiftUI

public extension View {
    /// Adds a Done key above the keyboard so text entry is never a trap:
    /// users can always dismiss the keyboard without killing the app.
    func dismissibleKeyboard() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
            }
        }
    }
}

public struct PriorityBadge: View {
    public let priority: AssignmentPriority

    public init(priority: AssignmentPriority) {
        self.priority = priority
    }

    public var body: some View {
        HStack(spacing: 3) {
            Image(systemName: StudyOSTheme.priorityIcon(for: priority))
                .imageScale(.small)
            Text(priority.rawValue)
                .font(.caption2.weight(.medium))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(StudyOSTheme.priorityColor(for: priority).opacity(0.12))
        .foregroundStyle(StudyOSTheme.priorityColor(for: priority))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Priority: \(priority.rawValue)")
    }
}

public struct StatusPill: View {
    public let status: AssignmentStatus

    public init(status: AssignmentStatus) {
        self.status = status
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusSymbolName)
                .foregroundStyle(statusColor)
            Text(status.rawValue)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Status: \(status.rawValue)")
    }

    /// Icon shape communicates state redundantly with color for
    /// color-blind users and Increase Contrast.
    private var statusSymbolName: String {
        switch status {
        case .completed: return "checkmark.circle.fill"
        case .inProgress: return "circle.lefthalf.filled"
        case .notStarted: return "circle"
        case .overdue: return "exclamationmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch status {
        case .completed: return .green
        case .inProgress: return .blue
        case .notStarted: return .secondary
        case .overdue: return .red
        }
    }
}

public struct SubjectTag: View {
    public let subject: String

    public init(subject: String) {
        self.subject = subject
    }

    public var body: some View {
        Text(subject)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(StudyOSTheme.subjectColor(for: subject))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(StudyOSTheme.subjectColor(for: subject).opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

public struct StudyOSEmptyState: View {
    public let title: String
    public let systemImage: String
    public let description: String
    public let actionTitle: String?
    public let action: (() -> Void)?

    public init(
        title: String,
        systemImage: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } actions: {
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.body.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
        }
    }
}

public struct StudyOSErrorBanner: View {
    public let title: String
    public let message: String
    public let retryAction: (() -> Void)?

    public init(title: String, message: String, retryAction: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .imageScale(.medium)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let retry = retryAction {
                Button("Retry", action: retry)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
