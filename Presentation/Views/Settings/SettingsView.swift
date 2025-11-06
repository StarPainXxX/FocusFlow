//
//  SettingsView.swift
//  FocusFlow
//
//  设置视图
//

import SwiftUI
import SwiftData
import Foundation

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Query private var sessions: [FocusSession]
    @Query private var tasks: [Task]
    @Query private var tags: [Tag]
    @Query private var achievements: [Achievement]
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var selectedTheme: String = "light"
    @State private var dailyGoal: Int = 240
    @State private var weeklyGoal: Int = 1680
    @State private var preferredDuration: Int = 25
    @State private var showDeleteAllDataAlert = false
    
    // 辅助函数：获取白噪音显示名称
    private func whiteNoiseName(for id: String) -> String {
        switch id {
        case "none": return "无"
        case "rain": return "雨声"
        case "ocean": return "海浪"
        case "fire": return "篝火"
        case "night": return "夜晚"
        case "rain&birds": return "雨声与鸟鸣"
        default: return "无"
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if let user = users.first {
                    // 用户信息
                    Section("用户信息") {
                        HStack {
                            Text("显示名称")
                            Spacer()
                            Text(user.displayName ?? "未设置")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("等级")
                            Spacer()
                            Text("Lv.\(user.level) - \(user.levelName)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("经验值")
                            Spacer()
                            Text("\(user.exp)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("总专注时长")
                            Spacer()
                            Text("\(user.totalFocusTime) 分钟")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 目标设置
                    Section("目标设置") {
                        Stepper("每日目标: \(dailyGoal) 分钟", value: $dailyGoal, in: 15...600, step: 15)
                            .onChange(of: dailyGoal) { _, newValue in
                                user.dailyGoal = newValue
                                user.updatedAt = Date()
                                saveUser(user)
                            }
                        
                        Stepper("每周目标: \(weeklyGoal) 分钟", value: $weeklyGoal, in: 60...4200, step: 60)
                            .onChange(of: weeklyGoal) { _, newValue in
                                user.weeklyGoal = newValue
                                user.updatedAt = Date()
                                saveUser(user)
                            }
                        
                        Stepper("偏好时长: \(preferredDuration) 分钟", value: $preferredDuration, in: 5...180, step: 5)
                            .onChange(of: preferredDuration) { _, newValue in
                                user.preferredFocusDuration = newValue
                                user.updatedAt = Date()
                                saveUser(user)
                            }
                    }
                    
                    // 偏好设置
                    Section("偏好设置") {
                        Picker("主题", selection: $selectedTheme) {
                            Text("浅色").tag("light")
                            Text("深色").tag("dark")
                            Text("跟随系统").tag("system")
                        }
                        .onChange(of: selectedTheme) { _, newValue in
                            user.theme = newValue
                            user.updatedAt = Date()
                            saveUser(user)
                        }
                    }
                    
                    // 声音设置
                    Section("声音设置") {
                        Toggle("启用声音", isOn: $settingsManager.soundEnabled)
                            .onChange(of: settingsManager.soundEnabled) { _, _ in
                                settingsManager.saveSettings()
                            }
                        
                        if settingsManager.soundEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("音量: \(Int(settingsManager.soundVolume * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Slider(value: $settingsManager.soundVolume, in: 0...1, step: 0.1)
                                    .onChange(of: settingsManager.soundVolume) { _, _ in
                                        settingsManager.saveSettings()
                                    }
                            }
                            
                            Picker("开始提示音", selection: $settingsManager.selectedStartSound) {
                                ForEach(settingsManager.availableSounds, id: \.id) { sound in
                                    Text(sound.name).tag(sound.id)
                                }
                            }
                            .onChange(of: settingsManager.selectedStartSound) { _, _ in
                                settingsManager.saveSettings()
                            }
                            
                            Picker("暂停提示音", selection: $settingsManager.selectedPauseSound) {
                                ForEach(settingsManager.availableSounds, id: \.id) { sound in
                                    Text(sound.name).tag(sound.id)
                                }
                            }
                            .onChange(of: settingsManager.selectedPauseSound) { _, _ in
                                settingsManager.saveSettings()
                            }
                            
                            Picker("专注完成提示音", selection: $settingsManager.selectedCompleteSound) {
                                ForEach(settingsManager.availableSounds, id: \.id) { sound in
                                    Text(sound.name).tag(sound.id)
                                }
                            }
                            .onChange(of: settingsManager.selectedCompleteSound) { _, _ in
                                settingsManager.saveSettings()
                            }
                            
                            Picker("休息完成提示音", selection: $settingsManager.selectedBreakCompleteSound) {
                                ForEach(settingsManager.availableSounds, id: \.id) { sound in
                                    Text(sound.name).tag(sound.id)
                                }
                            }
                            .onChange(of: settingsManager.selectedBreakCompleteSound) { _, _ in
                                settingsManager.saveSettings()
                            }
                        }
                    }
                    
                    // 通知设置
                    Section("通知设置") {
                        Toggle("启用通知", isOn: $settingsManager.notificationsEnabled)
                            .onChange(of: settingsManager.notificationsEnabled) { _, _ in
                                settingsManager.saveSettings()
                            }
                        
                        if settingsManager.notificationsEnabled {
                            Toggle("专注开始通知", isOn: $settingsManager.focusStartNotification)
                                .onChange(of: settingsManager.focusStartNotification) { _, _ in
                                    settingsManager.saveSettings()
                                }
                            
                            Toggle("专注暂停通知", isOn: $settingsManager.focusPauseNotification)
                                .onChange(of: settingsManager.focusPauseNotification) { _, _ in
                                    settingsManager.saveSettings()
                                }
                            
                            Toggle("专注完成通知", isOn: $settingsManager.focusCompleteNotification)
                                .onChange(of: settingsManager.focusCompleteNotification) { _, _ in
                                    settingsManager.saveSettings()
                                }
                            
                            Toggle("成就解锁通知", isOn: $settingsManager.achievementNotification)
                                .onChange(of: settingsManager.achievementNotification) { _, _ in
                                    settingsManager.saveSettings()
                                }
                            
                            Toggle("每日总结通知", isOn: $settingsManager.dailySummaryNotification)
                                .onChange(of: settingsManager.dailySummaryNotification) { _, _ in
                                    settingsManager.saveSettings()
                                }
                            
                            Toggle("每周总结通知", isOn: $settingsManager.weeklySummaryNotification)
                                .onChange(of: settingsManager.weeklySummaryNotification) { _, _ in
                                    settingsManager.saveSettings()
                                }
                            
                            Toggle("智能提醒通知", isOn: $settingsManager.smartReminderNotification)
                                .onChange(of: settingsManager.smartReminderNotification) { _, _ in
                                    settingsManager.saveSettings()
                                }
                        }
                    }
                    
                    // 专注设置
                    Section("专注设置") {
                        // 专注时启用勿扰模式（已禁用，不显示开关）
                        // Toggle("专注时启用勿扰模式（不可用）", isOn: $settingsManager.focusDndEnabled)
                        //     .onChange(of: settingsManager.focusDndEnabled) { _, _ in
                        //         settingsManager.saveSettings()
                        //     }
                        //     .disabled(true) // 禁用开关，因为功能不可用
                        
                        Toggle("锁屏和灵动岛专注", isOn: $settingsManager.liveActivityEnabled)
                            .onChange(of: settingsManager.liveActivityEnabled) { _, _ in
                                settingsManager.saveSettings()
                            }
                        
                        Stepper("休息时长: \(settingsManager.breakDuration) 分钟", value: $settingsManager.breakDuration, in: 1...60, step: 1)
                            .onChange(of: settingsManager.breakDuration) { _, _ in
                                settingsManager.saveSettings()
                            }
                        
                        Toggle("休息结束后自动开始新一轮专注", isOn: $settingsManager.autoStartAfterBreak)
                            .onChange(of: settingsManager.autoStartAfterBreak) { _, _ in
                                settingsManager.saveSettings()
                            }
                        
                        // 白噪音设置
                        Toggle("专注时播放白噪音", isOn: $settingsManager.whiteNoiseEnabled)
                            .onChange(of: settingsManager.whiteNoiseEnabled) { _, _ in
                                settingsManager.saveSettings()
                                if !settingsManager.whiteNoiseEnabled {
                                    WhiteNoiseManager.shared.stop()
                                }
                            }
                        
                        if settingsManager.whiteNoiseEnabled {
                            Picker("白噪音类型", selection: $settingsManager.selectedWhiteNoise) {
                                ForEach(["none", "rain", "ocean", "fire", "night", "rain&birds"], id: \.self) { noise in
                                    Text(whiteNoiseName(for: noise)).tag(noise)
                                }
                            }
                            .onChange(of: settingsManager.selectedWhiteNoise) { _, _ in
                                settingsManager.saveSettings()
                            }
                            
                            HStack {
                                Text("音量")
                                Spacer()
                                Slider(value: $settingsManager.whiteNoiseVolume, in: 0...1) {
                                    Text("音量")
                                } minimumValueLabel: {
                                    Text("0%")
                                        .font(.caption)
                                } maximumValueLabel: {
                                    Text("100%")
                                        .font(.caption)
                                }
                                .frame(width: 150)
                                Text("\(Int(settingsManager.whiteNoiseVolume * 100))%")
                                    .foregroundColor(.secondary)
                                    .frame(width: 40)
                            }
                            .onChange(of: settingsManager.whiteNoiseVolume) { _, _ in
                                settingsManager.saveSettings()
                                WhiteNoiseManager.shared.setVolume(settingsManager.whiteNoiseVolume)
                            }
                        }
                    }
                    
                    // [已注释] 专注锁定模式
                    // 由于iOS系统限制，应用屏蔽功能暂时禁用
                    /*
                    Section("专注锁定模式") {
                        Toggle("启用专注锁定", isOn: $settingsManager.focusLockEnabled)
                            .onChange(of: settingsManager.focusLockEnabled) { _, _ in
                                settingsManager.saveSettings()
                            }
                        
                        if settingsManager.focusLockEnabled {
                            Toggle("屏蔽所有应用（除了系统应用）", isOn: $settingsManager.blockAllAppsExceptSystem)
                                .onChange(of: settingsManager.blockAllAppsExceptSystem) { _, _ in
                                    settingsManager.saveSettings()
                                }
                            
                            NavigationLink(destination: BlockedAppsView()) {
                                HStack {
                                    Text("屏蔽应用列表")
                                    Spacer()
                                    if !settingsManager.blockedApps.isEmpty {
                                        Text("\(settingsManager.blockedApps.count)")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    */
                    
                    // 数据统计
                    Section("数据统计") {
                        HStack {
                            Text("总会话数")
                            Spacer()
                            Text("\(user.totalPomodoros)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("连续天数")
                            Spacer()
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("\(user.consecutiveDays) 天")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack {
                            Text("最长连续")
                            Spacer()
                            Text("\(user.bestStreak) 天")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 标签管理
                    Section("标签管理") {
                        NavigationLink(destination: TagsManagementView()) {
                            HStack {
                                Image(systemName: "tag")
                                Text("管理标签")
                            }
                        }
                    }
                    
                    // 数据管理
                    Section("数据管理") {
                        NavigationLink(destination: DataExportView()) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("导出数据")
                            }
                        }
                        
                        Button(role: .destructive) {
                            showDeleteAllDataAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("删除所有数据")
                            }
                        }
                    }
                    
                    // 关于
                    Section("关于") {
                        HStack {
                            Text("应用名称")
                            Spacer()
                            Text(AppConstants.appName)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("版本")
                            Spacer()
                            Text(AppConstants.appVersion)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    // 如果没有用户数据
                    Section {
                        Text("暂无用户数据")
                        .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let user = users.first {
                    selectedTheme = user.theme
                    dailyGoal = user.dailyGoal
                    weeklyGoal = user.weeklyGoal
                    preferredDuration = user.preferredFocusDuration
                }
            }
            .alert("删除所有数据", isPresented: $showDeleteAllDataAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("此操作将删除所有专注记录、任务、标签和成就数据。此操作无法撤销，确定要继续吗？")
            }
        }
    }
    
    private func saveUser(_ user: User) {
        do {
            try modelContext.save()
        } catch {
            Logger.error("保存用户设置失败: \(error.localizedDescription)", category: .data)
        }
    }
    
    // MARK: - 删除所有数据
    private func deleteAllData() {
        // 删除所有专注记录
        for session in sessions {
            modelContext.delete(session)
        }
        
        // 删除所有任务
        for task in tasks {
            modelContext.delete(task)
        }
        
        // 删除所有标签（保留默认标签逻辑在标签管理中处理）
        for tag in tags {
            modelContext.delete(tag)
        }
        
        // 删除所有成就
        for achievement in achievements {
            modelContext.delete(achievement)
        }
        
        // 重置用户数据
        if let user = users.first {
            user.totalFocusTime = 0
            user.exp = 0
            user.consecutiveDays = 0
            user.bestStreak = 0
            user.totalPomodoros = 0
            user.level = 1
            user.updatedAt = Date()
        }
        
        // 保存更改
        do {
            try modelContext.save()
            Logger.info("删除所有数据成功", category: .data)
            
            // 删除后重新创建默认任务和成就
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // 重新初始化默认成就
                AchievementUtils.initializeDefaultAchievements(context: modelContext)
                
                // 重新初始化默认任务
                _ = AchievementUtils.initializeDefaultTask(context: modelContext)
            }
        } catch {
            Logger.error("删除所有数据失败: \(error.localizedDescription)", category: .data)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [User.self])
}
