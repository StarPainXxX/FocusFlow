//
//  PomodoroView.swift
//  FocusFlow
//
//  番茄模式视图
//

import SwiftUI
import SwiftData

struct PomodoroView: View {
    @StateObject private var pomodoroViewModel = PomodoroViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showTaskPicker = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // 番茄计数器
                    pomodoroCounter
                    
                    // 当前阶段显示
                    phaseDisplay
                    
                    // 计时器区域
                    timerSection
                    
                    // 任务和标签选择
                    taskAndTagSection
                    
                    // 控制按钮
                    controlButtons
                    
                    // 番茄设置
                    pomodoroSettings
                }
                .padding()
            }
            .navigationTitle("番茄模式")
            .sheet(isPresented: $showTaskPicker) {
                TaskPickerView(selectedTask: $pomodoroViewModel.selectedTask)
            }
        }
        .onAppear {
            pomodoroViewModel.setModelContext(modelContext)
        }
    }
    
    // MARK: - 番茄计数器
    private var pomodoroCounter: some View {
        HStack(spacing: 10) {
            ForEach(0..<pomodoroViewModel.pomodorosBeforeLongBreak, id: \.self) { index in
                if index < pomodoroViewModel.completedPomodoros {
                    // 已完成的番茄：使用红色圆形填充
                    Image(systemName: "circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                } else {
                    // 未完成的番茄：使用灰色圆形边框
                    Image(systemName: "circle")
                        .font(.title)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 阶段显示
    private var phaseDisplay: some View {
        VStack(spacing: 10) {
            Text(pomodoroViewModel.phaseTitle)
                .font(.title)
                .fontWeight(.bold)
            
            Text(pomodoroViewModel.nextPhaseTitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - 计时器区域
    private var timerSection: some View {
        VStack(spacing: 20) {
            // 环形进度条
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                
                Circle()
                    .trim(from: 0, to: pomodoroViewModel.progress)
                    .stroke(
                        pomodoroViewModel.currentPhase == .work
                            ? AppColors.primary
                            : AppColors.success,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: pomodoroViewModel.progress)
                
                VStack {
                    Text(pomodoroViewModel.formattedTime)
                        .font(.system(size: 48, weight: .bold))
                        .monospacedDigit()
                    
                    Text("剩余 \(Int(pomodoroViewModel.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 250, height: 250)
        }
        .padding()
    }
    
    // MARK: - 任务选择
    private var taskAndTagSection: some View {
        // 任务选择
        HStack {
            Image(systemName: "checklist")
                .foregroundColor(.secondary)
            Text("任务:")
                .foregroundColor(.secondary)
            Spacer()
            Button(pomodoroViewModel.selectedTask?.name ?? "选择任务") {
                showTaskPicker = true
            }
            .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // MARK: - 控制按钮
    private var controlButtons: some View {
        HStack(spacing: 20) {
            if pomodoroViewModel.isRunning {
                if pomodoroViewModel.isPaused {
                    Button(action: {
                        pomodoroViewModel.resumePomodoro()
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
                        pomodoroViewModel.pausePomodoro()
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
                    pomodoroViewModel.stopPomodoro()
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
                    pomodoroViewModel.startPomodoro()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("开始番茄")
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
    
    // MARK: - 番茄设置
    private var pomodoroSettings: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("番茄设置:")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 10) {
                HStack {
                    Text("工作时长:")
                        .frame(width: 100, alignment: .leading)
                    Spacer()
                    Picker("", selection: $pomodoroViewModel.workDuration) {
                        ForEach([15, 20, 25, 30, 45, 60], id: \.self) { duration in
                            Text("\(duration)分钟").tag(duration)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                HStack {
                    Text("短休息:")
                        .frame(width: 100, alignment: .leading)
                    Spacer()
                    Picker("", selection: $pomodoroViewModel.shortBreakDuration) {
                        ForEach([3, 5, 10], id: \.self) { duration in
                            Text("\(duration)分钟").tag(duration)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                HStack {
                    Text("长休息:")
                        .frame(width: 100, alignment: .leading)
                    Spacer()
                    Picker("", selection: $pomodoroViewModel.longBreakDuration) {
                        ForEach([10, 15, 20, 30], id: \.self) { duration in
                            Text("\(duration)分钟").tag(duration)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

#Preview {
    PomodoroView()
}

