//
//  HomeView.swift
//  FocusFlow
//
//  首页视图
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject var focusViewModel: FocusViewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [FocusSession]
    @State private var showTaskPicker = false
    @State private var showTagPicker = false
    
    // 计算今日专注时长
    private var todayTotalMinutes: Int {
        let today = DateUtils.startOfToday()
        return sessions
            .filter { DateUtils.isSameDay($0.startTime, today) && $0.isCompleted }
            .reduce(0) { $0 + ($1.duration / 60) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // 顶部状态栏
                    topStatusBar
                    
                    // 计时器区域
                    timerSection
                    
                    // 任务和标签选择
                    taskAndTagSection
                    
                    // 控制按钮
                    controlButtons
                    
                    // 快捷时长按钮
                    quickDurationButtons
                    
                    // 番茄模式入口
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
                .padding()
            }
            .navigationTitle("专注")
            .navigationBarTitleDisplayMode(.large)
        }
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
                    Text("0 天")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 计时器区域
    private var timerSection: some View {
        VStack(spacing: 20) {
            // 环形进度条
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                
                Circle()
                    .trim(from: 0, to: focusViewModel.progress)
                    .stroke(
                        AppColors.primary,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: focusViewModel.progress)
                
                VStack {
                    Text(focusViewModel.formattedTime)
                        .font(.system(size: 48, weight: .bold))
                        .monospacedDigit()
                    
                    Text("剩余 \(Int(focusViewModel.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 250, height: 250)
        }
        .padding()
    }
    
    // MARK: - 任务和标签选择
    private var taskAndTagSection: some View {
        VStack(spacing: 15) {
            // 任务选择
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
            
            // 标签选择
            HStack {
                Image(systemName: "tag")
                    .foregroundColor(.secondary)
                Text("标签:")
                    .foregroundColor(.secondary)
                Spacer()
                if focusViewModel.selectedTags.isEmpty {
                    Button("添加标签") {
                        showTagPicker = true
                    }
                    .foregroundColor(.primary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(focusViewModel.selectedTags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppColors.primary.opacity(0.2))
                                    .foregroundColor(AppColors.primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
    
    // MARK: - 控制按钮
    private var controlButtons: some View {
        HStack(spacing: 20) {
            if focusViewModel.isRunning {
                if focusViewModel.isPaused {
                    Button(action: {
                        focusViewModel.resumeFocus()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("继续")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.success)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                } else {
                    Button(action: {
                        focusViewModel.pauseFocus()
                    }) {
                        HStack {
                            Image(systemName: "pause.fill")
                            Text("暂停")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.warning)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                
                Button(action: {
                    focusViewModel.stopFocus()
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("停止")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.error)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            } else {
                Button(action: {
                    focusViewModel.startFocus()
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
        }
    }
    
    // MARK: - 快捷时长按钮
    private var quickDurationButtons: some View {
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
                ForEach(AppConstants.presetDurations, id: \.self) { duration in
                    Button(action: {
                        focusViewModel.selectedDuration = duration
                    }) {
                        Text("\(duration)分钟")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                focusViewModel.selectedDuration == duration
                                    ? AppColors.primary
                                    : Color(.systemGray5)
                            )
                            .foregroundColor(
                                focusViewModel.selectedDuration == duration
                                    ? .white
                                    : .primary
                            )
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(FocusViewModel())
}

