//
//  HomeView.swift
//  FocusFlow
//
//  首页视图
//

import SwiftUI
import SwiftData
import Combine

struct HomeView: View {
    @EnvironmentObject var focusViewModel: FocusViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusSession.startTime, order: .reverse) private var sessions: [FocusSession]
    @Query private var users: [User]
    @State private var refreshID = UUID()
    @State private var showFocusSession = false // 是否显示专注界面
    @State private var showTaskPicker = false
    @State private var showCustomDuration = false
    @State private var customDurationText: String = ""
    
    // 计算今日专注时长
    private var todayTotalMinutes: Int {
        let today = DateUtils.startOfToday()
        let todaySessions = sessions.filter { DateUtils.isSameDay($0.startTime, today) && $0.isCompleted }
        let total = todaySessions.reduce(0) { $0 + ($1.duration / 60) }
        return total
    }
    
    // 获取用户连续天数
    private var consecutiveDays: Int {
        if let user = users.first {
            return user.consecutiveDays
        }
        // 如果没有用户数据，从sessions计算
        return StatisticsUtils.calculateConsecutiveDays(from: sessions)
    }
    
    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("专注")
                .navigationBarTitleDisplayMode(.inline)
                .fullScreenCover(isPresented: $showFocusSession) {
                    NavigationStack {
                        FocusSessionView()
                            .environmentObject(focusViewModel)
                    }
                }
                .sheet(isPresented: $showTaskPicker) {
                    TaskPickerView(selectedTask: $focusViewModel.selectedTask)
                }
        }
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 30) {
                // 顶部状态栏
                topStatusBar
                
                // 任务选择
                taskSelectionSection
                
                // 时长选择
                durationSelectionSection
                
                // 自定义时长输入
                customDurationSection
                
                // 开始专注按钮
                startButton
                
                // 番茄模式入口
                pomodoroButton
            }
            .padding()
        }
            .onChange(of: sessions.count) { oldCount, newCount in
                // 当sessions数量变化时刷新
                if newCount != oldCount {
                    refreshID = UUID()
                }
            }
            .onChange(of: sessions) { oldSessions, newSessions in
                // 当sessions变化时刷新
                let oldCompleted = oldSessions.filter { $0.isCompleted }.count
                let newCompleted = newSessions.filter { $0.isCompleted }.count
                if newCompleted != oldCompleted {
                    refreshID = UUID()
                }
            }
            .onChange(of: users) { _, _ in
                // 当users变化时刷新
                refreshID = UUID()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FocusSessionCompleted"))) { _ in
                // 当专注完成时，延迟刷新数据以确保数据已保存
                modelContext.processPendingChanges()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    refreshID = UUID()
                }
            }
            .onAppear {
                // 延迟初始化默认任务，避免阻塞UI
                _Concurrency.Task { @MainActor in
                    try? await _Concurrency.Task.sleep(nanoseconds: 50_000_000) // 0.05秒
                    
                    // 确保默认任务存在
                    if let defaultTask = AchievementUtils.initializeDefaultTask(context: modelContext) {
                        // 如果没有选择任务，自动选择默认任务
                        if focusViewModel.selectedTask == nil {
                            focusViewModel.selectedTask = defaultTask
                        }
                    }
                }
            }
            .id(refreshID) // 强制刷新整个视图
    }
    
    // MARK: - 顶部状态栏
    private var topStatusBar: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("今日专注")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(todayTotalMinutes) 分钟")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("连续天数")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(consecutiveDays) 天")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 任务选择
    private var taskSelectionSection: some View {
        HStack {
            Image(systemName: "checklist")
                .foregroundColor(.secondary)
            Text("任务:")
                .foregroundColor(.secondary)
            Spacer()
            Button(focusViewModel.selectedTask?.name ?? "选择任务") {
                showTaskPicker = true
            }
            .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // MARK: - 时长选择
    private var durationSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("快捷时长:")
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach([10, 25, 45, 90], id: \.self) { duration in
                    Button(action: {
                        focusViewModel.selectedDuration = duration
                        showCustomDuration = false
                        customDurationText = ""
                    }) {
                        Text("\(duration)分钟")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50) // 固定高度，确保大小相同
                            .padding()
                            .background(
                                focusViewModel.selectedDuration == duration && !showCustomDuration
                                    ? AppColors.primary
                                    : Color(.systemGray5)
                            )
                            .foregroundColor(
                                focusViewModel.selectedDuration == duration && !showCustomDuration
                                    ? .white
                                    : .primary
                            )
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    // MARK: - 自定义时长输入
    private var customDurationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("自定义时长:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    withAnimation {
                        showCustomDuration.toggle()
                        if !showCustomDuration {
                            customDurationText = ""
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                }) {
                    Image(systemName: showCustomDuration ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    showCustomDuration.toggle()
                }
            }
            
            if showCustomDuration {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        TextField("输入分钟数（1-300）", text: $customDurationText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: customDurationText) { oldValue, newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered != newValue {
                                    customDurationText = filtered
                                }
                                
                                if let minutes = Int(filtered), minutes >= 1 && minutes <= 300 {
                                    focusViewModel.selectedDuration = minutes
                                }
                            }
                        
                        Button(action: {
                            applyCustomDuration()
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }) {
                            Text("确定")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(isValidCustomDuration ? AppColors.primary : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(customDurationText.isEmpty || !isValidCustomDuration)
                    }
                    
                    if !customDurationText.isEmpty && !isValidCustomDuration {
                        Text("请输入 1-300 分钟之间的数字")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.top, 5)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // MARK: - 开始专注按钮
    private var startButton: some View {
        Button(action: {
            // 确保默认任务存在
            if let defaultTask = AchievementUtils.initializeDefaultTask(context: modelContext) {
                if focusViewModel.selectedTask == nil {
                    focusViewModel.selectedTask = defaultTask
                }
            }
            // 直接开始专注
            focusViewModel.startFocus()
            // 显示专注界面
            showFocusSession = true
        }) {
            HStack {
                Image(systemName: "play.fill")
                Text("开始专注")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColors.primary)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
    
    // MARK: - 番茄模式入口
    private var pomodoroButton: some View {
        NavigationLink(destination: PomodoroView()) {
            HStack {
                Image(systemName: "timer")
                Text("切换到番茄模式")
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(AppColors.primary.opacity(0.1))
            .foregroundColor(AppColors.primary)
            .cornerRadius(10)
        }
    }
    
    // MARK: - 辅助方法
    private func durationText(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)分钟"
        } else {
            let hours = minutes / 60
            return "\(hours)小时"
        }
    }
    
    private var isValidCustomDuration: Bool {
        guard let minutes = Int(customDurationText) else { return false }
        return minutes >= 1 && minutes <= 300
    }
    
    private func applyCustomDuration() {
        guard let minutes = Int(customDurationText),
              minutes >= 1 && minutes <= 300 else {
            return
        }
        focusViewModel.selectedDuration = minutes
    }
    
    
    // MARK: - 进度条颜色（最后1分钟变红）
    private var progressColor: Color {
        // 如果剩余时间少于1分钟，显示红色警示
        if focusViewModel.remainingSeconds <= 60 && focusViewModel.isRunning {
            return .red
        }
        return AppColors.primary
    }
}

#Preview {
    HomeView()
        .environmentObject(FocusViewModel())
}

