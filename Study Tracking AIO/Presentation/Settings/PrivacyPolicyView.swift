//
//  PrivacyPolicyView.swift
//  StudyOS
//

import SwiftUI

/// Centralized legal text and configurable public URLs for StudyOS.
///
/// The policy text lives here — and only here — so it can be reviewed and
/// updated in one place. The public policy URL and support address are read
/// from Info.plist keys (`PrivacyPolicyURL`, `SupportEmail`) when the
/// developer configures them; when absent, the corresponding UI is hidden
/// rather than showing placeholder links.
public enum PrivacyPolicyContent {

    /// Hosted privacy policy, if the developer configured one.
    public static var policyURL: URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "PrivacyPolicyURL") as? String,
              !raw.isEmpty else { return nil }
        return URL(string: raw)
    }

    /// Support contact, if the developer configured one.
    public static var supportEmail: String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SupportEmail") as? String,
              !raw.isEmpty else { return nil }
        return raw
    }

    public struct Section: Identifiable {
        public let id: String
        public let title: String
        public let body: String

        public init(id: String, title: String, body: String) {
            self.id = id
            self.title = title
            self.body = body
        }
    }

    /// The in-app privacy policy. Each statement must match actual behavior.
    public static let sections: [Section] = [
        Section(
            id: "overview",
            title: "Overview",
            body: """
            StudyOS is a local-first study planner. Your assignments, courses, schedule, study history, notes, and imported documents are stored on your device by default. You can use every core feature of StudyOS without an account, and no account is created for you.
            """
        ),
        Section(
            id: "storage",
            title: "Data Storage",
            body: """
            Your StudyOS assignments, planner data, imported materials, and study history are stored on your device by default. Documents you import are saved in the app's storage on the device and are not copied anywhere else. This data is kept until you delete it, either inside StudyOS or by uninstalling the app.
            """
        ),
        Section(
            id: "classroom",
            title: "Google Classroom (Optional)",
            body: """
            If you choose to connect Google Classroom, StudyOS requests read-only access to your course list and coursework. It reads course names, teacher names, assignment titles, descriptions, and due dates, and stores them on your device like any other assignment.

            StudyOS only asks for two Classroom read-only scopes. It never requests Gmail, Drive, Calendar, or Contacts, and it never writes to Classroom.

            When you connect Classroom, sign-in is handled by Google, and StudyOS stores its access tokens only in your device's Keychain. Requests during sync go to Google's Classroom API. Google handles your sign-in information under Google's own privacy policy. If your school manages your Google account, your administrator's settings may prevent third-party apps like StudyOS from connecting at all; StudyOS works normally without the connection.

            Disconnecting Classroom removes the stored tokens from your device. Assignments that were already imported stay on your device unless you delete them.
            """
        ),
        Section(
            id: "ai",
            title: "AI Processing",
            body: """
            StudyOS's study tools — summaries, explanations, flashcards, and quizzes — are generated on your device using Apple's on-device NaturalLanguage framework. The text of your materials and assignments is not uploaded to StudyOS or to a third-party AI service to generate them.

            AI output is a study aid based on the material you provide. It can be imperfect, so treat it as a suggestion rather than an authoritative source.
            """
        ),
        Section(
            id: "thirdparties",
            title: "Third Parties",
            body: """
            StudyOS contains no advertising SDKs, no tracking SDKs, and no analytics. StudyOS does not sell or share your data. The only third-party service StudyOS can communicate with is Google's Classroom API, and only if you connect Google Classroom.
            """
        ),
        Section(
            id: "notifications",
            title: "Notifications",
            body: """
            Reminders are scheduled locally on your device using iOS notifications. They are not delivered through a server, and StudyOS does not send any data off the device to create them. You can disable notifications in iOS Settings at any time; the rest of StudyOS keeps working.
            """
        ),
        Section(
            id: "permissions",
            title: "Permissions",
            body: """
            Camera: used only when you scan a worksheet, so its text can be extracted on-device.
            Photo Library: accessed only when you import a photo as study material.
            Files: accessed only when you import a document.
            Local Network & Location: not used. StudyOS does not request them.
            """
        ),
        Section(
            id: "retention",
            title: "Retention & Deletion",
            body: """
            Your data is retained on your device until you remove it. "Delete All Local Data" in Settings > Privacy & Security erases assignments, courses, materials, sessions, and reminders, and removes StudyOS items from Spotlight search. Disconnecting Google Classroom erases stored sign-in tokens. Uninstalling the app removes its local data and documents.
            """
        ),
        Section(
            id: "children",
            title: "School-Managed Accounts",
            body: """
            If you use a school-managed Google Workspace account, your school's administrator controls whether third-party applications can connect to it. StudyOS never attempts to bypass those restrictions, and all of its features except Classroom import work regardless.
            """
        ),
        Section(
            id: "changes",
            title: "Changes to This Policy",
            body: """
            If StudyOS adds features that change how data is handled — for example, an optional cloud service or a third-party AI provider — this policy will be updated to describe that handling before those features ship.
            """
        )
    ]
}

/// The in-app Privacy Policy screen. Renders the centralized text; offers the
/// hosted policy link only when one is configured.
public struct PrivacyPolicyView: View {
    public init() {}

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                Text("Privacy Policy")
                    .font(.largeTitle.weight(.bold))
                Text("Last updated: September 2026")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                ForEach(PrivacyPolicyContent.sections) { section in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(section.title)
                            .font(.title3.weight(.semibold))
                        Text(section.body)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(Text("\(section.title). \(section.body)"))
                    }
                    .accessibilityElement(children: .contain)
                }

                if let url = PrivacyPolicyContent.policyURL {
                    Link(destination: url) {
                        Label("Read the full policy online", systemImage: "safari")
                            .font(.body.weight(.medium))
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.platformSystemGroupedBackground)
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}
