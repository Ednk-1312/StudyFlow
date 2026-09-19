//
//  ContentView.swift
//  StudyOS
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .environment(AppState.shared)
        .modelContainer(StudyOSSchema.createModelContainer(inMemory: true))
}
