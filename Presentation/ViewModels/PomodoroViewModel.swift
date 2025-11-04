//
//  PomodoroViewModel.swift
//  FocusFlow
//
//  番茄模式视图模型
//

import Foundation
import SwiftUI
import Combine
import SwiftData

@MainActor
class PomodoroViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var currentPhase: PomodoroPhase = .work
    @Published var remainingSeconds: Int = 0
    @Published var totalSeconds: Int = 0
    @Published var currentPomodoro: Int = 0 // 当前是第几个番茄
    @Published var completedPomodoros: Int = 0 // 已完成的番茄数
    @Published var selectedTask: Task?
    @Published var selectedTags: [String] = []
    @Published var notes: String = ""
    
    // MARK: - Settings
    @Published var workDuration: Int = 25 // 工作时段（分钟）
    @Published var shortBreakDuration: Int = 5 // 短休息（分钟）
    @Published var longBreakDuration: Int = 15 // 长休息（分钟）
    @Published var pomodorosBeforeLongBreak: Int = 4 // 几个番茄后长休息
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var startTime: Date?
    private var pausedTime: Date?
    private var accumulatedPauseTime: TimeInterval = 0
    private var modelContext: ModelContext?
    private var currentSession: FocusSession?
    
    // MARK: - Computed Properties
    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(totalSeconds))
    }
    
    var formattedTime: String {
        DateUtils.formatDurationFromSeconds(remainingSeconds)
    }
    
    var phaseTitle: String {
        switch currentPhase {
        case .work:
            return "专注中"
        case .shortBreak:
            return "短休息"
        case .longBreak:
            return "长休息"
        }
    }
    
    var nextPhaseTitle: String {
        switch currentPhase {
        case .work:
            if (completedPomodoros + 1) % pomodorosBeforeLongBreak == 0 {
                return "长休息 \(longBreakDuration) 分钟后开始"
            } else {
                return "短休息 \(shortBreakDuration) 分钟后开始"
            }
        case .shortBreak, .longBreak:
            return "专注 \(workDuration) 分钟后开始"
        }
    }
    
    // MARK: - Initialization
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Methods
    /// 开始番茄
    func startPomodoro() {
        guard !isRunning else { return }
        
        // 如果是从暂停恢复
        if isPaused {
            resumePomodoro()
            return
        }
        
        // 开始新的阶段
        startPhase()
    }
    
    /// 开始阶段
    private func startPhase() {
        // 根据当前阶段设置时长
        let duration: Int
        switch currentPhase {
        case .work:
            duration = workDuration
            currentPomodoro += 1
        case .shortBreak:
            duration = shortBreakDuration
        case .longBreak:
            duration = longBreakDuration
        }
        
        totalSeconds = duration * 60
        remainingSeconds = totalSeconds
        startTime = Date()
        accumulatedPauseTime = 0
        isRunning = true
        isPaused = false
        
        // 创建专注记录（仅在工作阶段）
        if currentPhase == .work {
            let userId = "default-user" // TODO: 从用户系统获取
            currentSession = FocusSession(
                userId: userId,
                startTime: startTime!,
                plannedDuration: duration * 60,
                type: .pomodoro,
                mode: .work,
                taskId: selectedTask?.id,
                taskName: selectedTask?.name,
                tags: selectedTags,
                device: .ios
            )
        }
        
        // 发送开始通知
        NotificationManager.shared.sendFocusStartNotification(duration: duration)
        
        startTimer()
        Logger.info("开始番茄阶段: \(currentPhase), 时长: \(duration)分钟", category: .timer)
    }
    
    /// 暂停番茄
    func pausePomodoro() {
        guard isRunning && !isPaused else { return }
        
        pausedTime = Date()
        isPaused = true
        timer?.invalidate()
        timer = nil
        
        Logger.info("暂停番茄", category: .timer)
    }
    
    /// 恢复番茄
    func resumePomodoro() {
        guard isPaused else { return }
        
        if let pausedTime = pausedTime {
            let pauseDuration = Date().timeIntervalSince(pausedTime)
            accumulatedPauseTime += pauseDuration
        }
        
        pausedTime = nil
        isPaused = false
        startTimer()
        
        Logger.info("恢复番茄", category: .timer)
    }
    
    /// 停止番茄
    func stopPomodoro() {
        timer?.invalidate()
        timer = nil
        
        // 保存当前阶段的记录（如果正在工作）
        if currentPhase == .work, let session = currentSession, let context = modelContext {
            let endTime = Date()
            let actualSeconds = Int(endTime.timeIntervalSince(session.startTime))
            
            session.endTime = endTime
            session.duration = actualSeconds
            session.isCompleted = false
            session.updatedAt = Date()
            session.syncStatus = .pending
            
            context.insert(session)
            do {
                try context.save()
            } catch {
                Logger.error("保存停止记录失败: \(error.localizedDescription)", category: .data)
            }
        }
        
        isRunning = false
        isPaused = false
        remainingSeconds = 0
        totalSeconds = 0
        startTime = nil
        pausedTime = nil
        accumulatedPauseTime = 0
        currentSession = nil
        
        Logger.info("停止番茄", category: .timer)
    }
    
    // MARK: - Private Methods
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    private func tick() {
        guard isRunning && !isPaused else { return }
        
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        } else {
            completePhase()
        }
    }
    
    private func completePhase() {
        timer?.invalidate()
        timer = nil
        
        // 完成当前阶段
        switch currentPhase {
        case .work:
            // 完成工作阶段，保存记录
            if let session = currentSession, let context = modelContext {
                let endTime = Date()
                let actualSeconds = Int(endTime.timeIntervalSince(session.startTime))
                
                session.endTime = endTime
                session.duration = actualSeconds
                session.isCompleted = true
                session.updatedAt = Date()
                session.syncStatus = .pending
                
                context.insert(session)
                do {
                    try context.save()
                    Logger.info("保存番茄记录成功: \(session.id)", category: .data)
                } catch {
                    Logger.error("保存番茄记录失败: \(error.localizedDescription)", category: .data)
                }
            }
            
            completedPomodoros += 1
            currentSession = nil
            
            // 发送完成通知
            NotificationManager.shared.sendFocusCompleteNotification(
                duration: workDuration,
                taskName: selectedTask?.name
            )
            
            // 判断下一个阶段
            if completedPomodoros % pomodorosBeforeLongBreak == 0 {
                // 长休息
                currentPhase = .longBreak
            } else {
                // 短休息
                currentPhase = .shortBreak
            }
            
            // 自动开始休息
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                Task { @MainActor in
                    self.startPhase()
                }
            }
            
        case .shortBreak, .longBreak:
            // 完成休息，开始工作
            currentPhase = .work
            
            // 自动开始工作
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                Task { @MainActor in
                    self.startPhase()
                }
            }
        }
        
        Logger.info("完成阶段: \(currentPhase)", category: .timer)
    }
    
    deinit {
        timer?.invalidate()
    }
}

// MARK: - 番茄阶段枚举
enum PomodoroPhase {
    case work
    case shortBreak
    case longBreak
}

