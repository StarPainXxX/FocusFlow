//
//  FocusSessionView.swift
//  FocusFlow
//
//  专注会话视图（全屏专注界面）
//

import SwiftUI
import SwiftData

struct FocusSessionView: View {
    @EnvironmentObject var focusViewModel: FocusViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showExitAlert = false
    @Query private var tags: [Tag] // 用于获取标签信息
    @Query(sort: \FocusSession.startTime, order: .reverse) private var sessions: [FocusSession] // 用于计算今日专注时长
    
    // 计算今日专注时长
    private var todayTotalMinutes: Int {
        let today = DateUtils.startOfToday()
        let todaySessions = sessions.filter { DateUtils.isSameDay($0.startTime, today) && $0.isCompleted }
        let total = todaySessions.reduce(0) { $0 + ($1.duration / 60) }
        return total
    }
    
    // 格式化今日专注时长显示
    private var todayFocusDurationText: String {
        if todayTotalMinutes >= 60 {
            let hours = todayTotalMinutes / 60
            let minutes = todayTotalMinutes % 60
            if minutes == 0 {
                return "\(hours)小时"
            } else {
                return "\(hours)小时\(minutes)分钟"
            }
        } else {
            return "\(todayTotalMinutes)分钟"
        }
    }
    
    var body: some View {
        ZStack {
            // 背景色
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部左侧：今日专注时长显示
                HStack {
                    todayFocusDurationCard
                        .padding(EdgeInsets(top: 10, leading: 20, bottom: 0, trailing: 0))
                    Spacer()
                }
                
                // 顶部：任务名称和标签（按照图三比例，进一步上移）
                topHeader
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                
                Spacer()
                
                // 中间：圆形计时器（按照图三比例，向上移动）
                timerSection
                    .frame(maxWidth: .infinity)
                
                Spacer()
                
                // 底部：交互按钮（按照图三比例，增加按钮间距）
                Group {
                    if focusViewModel.isBreakTime {
                        breakControls
                    } else {
                        focusControls
                    }
                }
                .padding(.bottom, 60)
                .padding(.horizontal, 40)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showExitAlert = true
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                        .font(.title3)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .alert("退出专注", isPresented: $showExitAlert) {
            Button("取消", role: .cancel) { }
            Button("退出", role: .destructive) {
                focusViewModel.stopFocus()
                dismiss()
            }
        } message: {
            Text("确定要退出专注吗？这将结束当前的专注会话。")
        }
        .onAppear {
            // 如果还没有开始专注，自动开始（从主页面点击开始后直接进入）
            if !focusViewModel.isRunning && !focusViewModel.isBreakTime {
                focusViewModel.startFocus()
            }
            
            // 延迟初始化默认任务，避免阻塞UI
            _Concurrency.Task { @MainActor in
                try? await _Concurrency.Task.sleep(nanoseconds: 50_000_000) // 0.05秒
                
                // 确保默认任务存在
                if let defaultTask = AchievementUtils.initializeDefaultTask(context: modelContext) {
                    if focusViewModel.selectedTask == nil {
                        focusViewModel.selectedTask = defaultTask
                    }
                }
            }
        }
    }
    
    // MARK: - 今日专注时长卡片
    private var todayFocusDurationCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("今日专注")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(todayFocusDurationText)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - 顶部标题区域
    private var topHeader: some View {
        VStack(spacing: 8) {
            // 任务名称（标题）
            Text(focusViewModel.selectedTask?.name ?? "专注")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
            
            // 标签（副标题）
            if let task = focusViewModel.selectedTask, let firstTagName = task.tags.first {
                // 获取标签颜色
                let tagColor = getTagColor(for: firstTagName)
                
                Text(firstTagName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(tagColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(tagColor.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - 计时器区域
    private var timerSection: some View {
        ZStack {
            // 背景圆环
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
            
            if focusViewModel.isBreakTime {
                // 休息时间
                Circle()
                    .trim(from: 0, to: breakProgress)
                    .stroke(
                        AppColors.success,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: breakProgress)
            } else {
                // 专注时间
                Circle()
                    .trim(from: 0, to: focusViewModel.progress)
                    .stroke(
                        progressColor,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: focusViewModel.progress)
            }
            
            // 时间显示
            Text(focusViewModel.isBreakTime ? breakFormattedTime : focusViewModel.formattedTime)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.primary)
        }
        .frame(width: 280, height: 280)
    }
    
    // MARK: - 专注控制按钮（圆形按钮）
    private var focusControls: some View {
        HStack(spacing: 50) {
            if focusViewModel.isRunning {
                if focusViewModel.isPaused {
                    // 暂停状态：显示"继续"和"重置"
                    // 继续按钮（圆形，蓝色）
                    Button(action: {
                        focusViewModel.resumeFocus()
                    }) {
                        ZStack {
                            Circle()
                                .fill(AppColors.primary)
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: "play.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                    }
                    
                    // 重置按钮（圆形，灰色）
                    Button(action: {
                        focusViewModel.resetFocus()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.primary)
                                .font(.title2)
                        }
                    }
                } else {
                    // 运行状态：显示"暂停"和"重置"
                    // 暂停按钮（圆形，橙色）
                    Button(action: {
                        focusViewModel.pauseFocus()
                    }) {
                        ZStack {
                            Circle()
                                .fill(AppColors.warning)
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: "pause.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                    }
                    
                    // 重置按钮（圆形，灰色）
                    Button(action: {
                        focusViewModel.resetFocus()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.primary)
                                .font(.title2)
                        }
                    }
                }
            } else {
                // 未开始：显示"开始"按钮（圆形，蓝色）
                Button(action: {
                    focusViewModel.startFocus()
                }) {
                    ZStack {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: "play.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
            }
        }
    }
    
    // MARK: - 休息控制按钮
    private var breakControls: some View {
        VStack(spacing: 20) {
            if focusViewModel.showBreakCompletion {
                // 休息完成：显示"继续"和"结束"
                HStack(spacing: 50) {
                    // 继续按钮（圆形，绿色）
                    Button(action: {
                        focusViewModel.continueAfterBreak()
                    }) {
                        ZStack {
                            Circle()
                                .fill(AppColors.success)
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: "play.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                    }
                    
                    // 结束按钮（圆形，红色）
                    Button(action: {
                        focusViewModel.endAfterBreak()
                        dismiss()
                    }) {
                        ZStack {
                            Circle()
                                .fill(AppColors.error)
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                    }
                }
            } else {
                // 休息中：显示"休息中"提示
                Text("休息中...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - 计算属性
    private var progressColor: Color {
        if focusViewModel.remainingSeconds <= 60 && focusViewModel.isRunning {
            return .red
        }
        return AppColors.primary
    }
    
    private var breakProgress: Double {
        guard focusViewModel.breakTotalSeconds > 0 else { return 0 }
        return 1.0 - (Double(focusViewModel.breakRemainingSeconds) / Double(focusViewModel.breakTotalSeconds))
    }
    
    private var breakFormattedTime: String {
        DateUtils.formatDurationFromSeconds(focusViewModel.breakRemainingSeconds)
    }
    
    // MARK: - 辅助方法
    /// 获取标签颜色
    private func getTagColor(for tagName: String) -> Color {
        let tagDescriptor = FetchDescriptor<Tag>(
            predicate: #Predicate<Tag> { tag in
                tag.name == tagName
            }
        )
        
        if let tag = try? modelContext.fetch(tagDescriptor).first {
            return Color(hex: tag.color)
        }
        
        return AppColors.primary
    }
}

#Preview {
    FocusSessionView()
        .environmentObject(FocusViewModel())
}
