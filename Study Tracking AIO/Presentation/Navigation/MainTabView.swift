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

#if os(macOS)
        NavigationSplitView {
            List(selection: $state.selectedTab) {
                ForEach(AppTab.allCases) { tab in
                    Label(tab.rawValue, systemImage: tab.systemImage)
                        .tag(tab)
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .navigationTitle("StudyFlow")
        } detail: {
            detailView
        }
        .sheet(isPresented: $state.isStudyAIPresented) {
            StudyAIHubView()
                .macSheetSizing()
        }
        .sheet(isPresented: $state.isSettingsPresented) {
            SettingsView()
                .macSheetSizing()
        }
        // Quick-add / scan are presented here (not in HomeView) on macOS so
        // the File-menu commands work from every sidebar section.
        .sheet(isPresented: $state.isQuickAddPresented) {
            QuickAddSheet()
                .macSheetSizing()
        }
        .sheet(isPresented: $state.isScanPresented) {
            ScanAssignmentView()
                .macSheetSizing()
        }
        // A running timer must not be escapable with Esc — only explicit
        // Finish/Complete flows inside the view may close it.
        .sheet(isPresented: $state.isStudySessionActive) {
            ActiveStudySessionView(
                assignment: appState.activeStudySessionAssignment,
                initialDurationMinutes: appState.activeSessionPlannedMinutes
            )
            .interactiveDismissDisabled()
            .macSheetSizing()
        }
        .overlay(alignment: .bottom) {
            toastOverlay
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
#else
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
            toastOverlay
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
#endif
    }

#if os(macOS)
    @ViewBuilder
    private var detailView: some View {
        switch appState.selectedTab {
        case .home: HomeView()
        case .assignments: AssignmentListView()
        case .planner: PlannerCalendarView()
        case .materials: MaterialsListView()
        case .utilities: UtilitiesHubView()
        }
    }
#endif

    @ViewBuilder
    private var toastOverlay: some View {
        if let toast = appState.currentToast {
            UndoToastView(message: toast.message, undoAction: toast.undoAction)
#if os(macOS)
                .padding(.bottom, 24)
#else
                .padding(.bottom, 84)
#endif
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

/// Presents the quick-add and scan sheets where AppState's presentation flags
/// are consumed. On macOS the window root owns them so the File-menu commands
/// work from every sidebar section; on iOS HomeView keeps them attached.
struct QuickAccessSheets: ViewModifier {
    let appState: AppState

    func body(content: Content) -> some View {
        @Bindable var state = appState
#if os(macOS)
        content
#else
        content
            .sheet(isPresented: $state.isQuickAddPresented) {
                QuickAddSheet()
            }
            .sheet(isPresented: $state.isScanPresented) {
                ScanAssignmentView()
            }
#endif
    }
}
