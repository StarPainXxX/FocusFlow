//
//  ContentView.swift
//  FocusFlow
//
//  根视图
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var focusViewModel = FocusViewModel()
    @State private var selectedTab = 0
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("专注", systemImage: "timer")
                }
                .tag(0)
            
            StatisticsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar")
                }
                .tag(1)
            
            TasksView()
                .tabItem {
                    Label("任务", systemImage: "checklist")
                }
                .tag(2)
            
            AchievementsView()
                .tabItem {
                    Label("成就", systemImage: "trophy")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
                .tag(4)
        }
        .environmentObject(focusViewModel)
        .onAppear {
            focusViewModel.setModelContext(modelContext)
        }
    }
}

#Preview {
    ContentView()
}

