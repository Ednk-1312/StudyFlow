//
//  MainTabView.swift
//  StudyOS
//

import SwiftUI

public struct MainTabView: View {
    @Environment(AppState.self) private var appState

    public init() {}

    public var body: some View {
        @Bindable var state = appState

        TabView(selection: $state.selectedTab) {
            HomeView()
                .tabItem {
                    Label(AppTab.home.rawValue, systemImage: AppTab.home.systemImage)
                }
                .tag(AppTab.home)

            AssignmentListView()
                .tabItem {
                    Label(AppTab.assignments.rawValue, systemImage: AppTab.assignments.systemImage)
                }
                .tag(AppTab.assignments)

            PlannerCalendarView()
                .tabItem {
                    Label(AppTab.planner.rawValue, systemImage: AppTab.planner.systemImage)
                }
                .tag(AppTab.planner)

            MaterialsListView()
                .tabItem {
                    Label(AppTab.materials.rawValue, systemImage: AppTab.materials.systemImage)
                }
                .tag(AppTab.materials)

            UtilitiesHubView()
                .tabItem {
                    Label(AppTab.utilities.rawValue, systemImage: AppTab.utilities.systemImage)
                }
                .tag(AppTab.utilities)
        }
        .sheet(isPresented: $state.isStudyAIPresented) {
            StudyAIHubView()
        }
        .sheet(isPresented: $state.isSettingsPresented) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $state.isStudySessionActive) {
            ActiveStudySessionView(
                assignment: appState.activeStudySessionAssignment,
                initialDurationMinutes: appState.activeSessionPlannedMinutes
            )
        }
        .overlay(alignment: .bottom) {
            if let toast = appState.currentToast {
                UndoToastView(message: toast.message, undoAction: toast.undoAction)
                    .padding(.bottom, 84)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.3), value: appState.currentToast?.id)
        .alert("Couldn't Save Change", isPresented: .init(
            get: { appState.dataErrorMessage != nil },
            set: { if !$0 { appState.dataErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appState.dataErrorMessage ?? "")
        }
    }
}
