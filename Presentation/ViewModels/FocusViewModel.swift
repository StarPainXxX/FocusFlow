//
//  FocusViewModel.swift
//  FocusFlow
//
//  专注视图模型
//

import Foundation
import SwiftUI
import Combine
import SwiftData

@MainActor
class FocusViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var remainingSeconds: Int = 0
    @Published var totalSeconds: Int = 0
    @Published var selectedDuration: Int = 25 // 默认25分钟
    @Published var selectedTask: Task?
    @Published var selectedTags: [String] = []
    @Published var notes: String = ""
    
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
    
    var isCompleted: Bool {
        remainingSeconds <= 0 && isRunning
    }
    
    // MARK: - Initialization
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Methods
    /// 开始专注
    func startFocus() {
        guard !isRunning else { return }
        
        // 如果是从暂停恢复
        if isPaused {
            resumeFocus()
            return
        }
        
        // 开始新的专注
        totalSeconds = selectedDuration * 60
        remainingSeconds = totalSeconds
        startTime = Date()
        accumulatedPauseTime = 0
        isRunning = true
        isPaused = false
        
        // 创建专注记录
        let userId = "default-user" // TODO: 从用户系统获取
        currentSession = FocusSession(
            userId: userId,
            startTime: startTime!,
            plannedDuration: selectedDuration * 60,
            type: .focus,
            mode: .work,
            taskId: selectedTask?.id,
            taskName: selectedTask?.name,
            tags: selectedTags,
            device: .ios
        )
        
        // 发送开始通知
        NotificationManager.shared.sendFocusStartNotification(duration: selectedDuration)
        
        startTimer()
        Logger.info("开始专注: \(selectedDuration)分钟", category: .timer)
    }
    
    /// 暂停专注
    func pauseFocus() {
        guard isRunning && !isPaused else { return }
        
        pausedTime = Date()
        isPaused = true
        timer?.invalidate()
        timer = nil
        
        Logger.info("暂停专注", category: .timer)
    }
    
    /// 恢复专注
    func resumeFocus() {
        guard isPaused else { return }
        
        if let pausedTime = pausedTime {
            let pauseDuration = Date().timeIntervalSince(pausedTime)
            accumulatedPauseTime += pauseDuration
        }
        
        pausedTime = nil
        isPaused = false
        startTimer()
        
        Logger.info("恢复专注", category: .timer)
    }
    
    /// 停止专注
    func stopFocus() {
        timer?.invalidate()
        timer = nil
        
        // 如果有关注记录，标记为未完成
        if let session = currentSession, let context = modelContext {
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
        
        Logger.info("停止专注", category: .timer)
    }
    
    /// 延长专注时间
    func extendDuration(minutes: Int) {
        guard isRunning else { return }
        remainingSeconds += minutes * 60
        totalSeconds += minutes * 60
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
            completeFocus()
        }
    }
    
    private func completeFocus() {
        // 计算实际专注时长
        let actualDuration = selectedDuration
        
        // 保存专注记录
        if let session = currentSession, let context = modelContext {
            let endTime = Date()
            let actualSeconds = Int(endTime.timeIntervalSince(session.startTime))
            
            session.endTime = endTime
            session.duration = actualSeconds
            session.isCompleted = true
            session.updatedAt = Date()
            session.syncStatus = .pending
            
            // 保存到数据库
            context.insert(session)
            do {
                try context.save()
                Logger.info("保存专注记录成功: \(session.id)", category: .data)
            } catch {
                Logger.error("保存专注记录失败: \(error.localizedDescription)", category: .data)
            }
        }
        
        stopFocus()
        currentSession = nil
        
        // 发送完成通知
        NotificationManager.shared.sendFocusCompleteNotification(
            duration: actualDuration,
            taskName: selectedTask?.name
        )
        
        Logger.info("专注完成: \(actualDuration)分钟", category: .timer)
    }
    
    deinit {
        timer?.invalidate()
    }
}

