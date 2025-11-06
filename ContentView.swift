//
//  ContentView.swift
//  FocusFlow
//
//  根视图
//

import SwiftUI
import SwiftData
import Combine

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
            
            // 延迟初始化默认数据，避免阻塞UI渲染
            // 先让UI显示出来，再在后台执行初始化
            _Concurrency.Task { @MainActor in
                // 等待一小段时间，确保UI已经渲染
                try? await _Concurrency.Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                
                // 检查是否已经初始化过（避免重复初始化）
                let userDescriptor = FetchDescriptor<User>()
                if let users = try? modelContext.fetch(userDescriptor), !users.isEmpty {
                    // 如果用户已存在，说明已经初始化过，只设置默认任务
                    if let defaultTask = AchievementUtils.initializeDefaultTask(context: modelContext) {
                        if focusViewModel.selectedTask == nil {
                            focusViewModel.selectedTask = defaultTask
                        }
                    }
                    return
                }
                
                // 初始化默认用户（如果还没有）
                let defaultUser = User(
                    displayName: "用户",
                    dailyGoal: 240,
                    weeklyGoal: 1680,
                    preferredFocusDuration: 45
                )
                modelContext.insert(defaultUser)
                do {
                    try modelContext.save()
                    Logger.info("初始化默认用户成功", category: .data)
                } catch {
                    Logger.error("初始化默认用户失败: \(error.localizedDescription)", category: .data)
                }
                
                // 批量初始化：成就、标签、任务
                // 初始化默认成就（如果还没有）
                let achievementDescriptor = FetchDescriptor<Achievement>()
                if let achievements = try? modelContext.fetch(achievementDescriptor), achievements.isEmpty {
                    AchievementUtils.initializeDefaultAchievements(context: modelContext)
                }
                
                // 初始化所有默认标签（学习、工作、阅读、编程、写作、运动、专注）
                AchievementUtils.initializeDefaultTags(context: modelContext)
                
                // 初始化默认任务"专注"（如果还没有）
                if let defaultTask = AchievementUtils.initializeDefaultTask(context: modelContext) {
                    // 如果FocusViewModel还没有选择任务，设置为默认任务
                    if focusViewModel.selectedTask == nil {
                        focusViewModel.selectedTask = defaultTask
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToFocusTab"))) { _ in
            // 切换到专注Tab
            selectedTab = 0
        }
    }
}

#Preview {
    ContentView()
}

