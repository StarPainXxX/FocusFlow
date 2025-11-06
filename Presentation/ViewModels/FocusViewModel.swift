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
import UserNotifications

@MainActor
class FocusViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var remainingSeconds: Int = 0
    @Published var totalSeconds: Int = 0
    @Published var selectedDuration: Int = 25 // 默认25分钟
    @Published var selectedTask: Task? {
        didSet {
            // 当任务改变时，自动更新标签（从任务中获取）
            selectedTags = selectedTask?.tags ?? []
        }
    }
    @Published var selectedTags: [String] = [] // 从任务中获取，不再手动选择
    @Published var notes: String = ""
    @Published var showCompletionAnimation = false
    @Published var lastCompletedDuration: Int = 0
    
    // MARK: - 休息状态
    @Published var isBreakTime = false
    @Published var breakRemainingSeconds: Int = 0
    @Published var breakTotalSeconds: Int = 0
    @Published var showBreakCompletion = false // 休息完成后显示"继续"和"结束"按钮
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var startTime: Date?
    private var pausedTime: Date?
    private var accumulatedPauseTime: TimeInterval = 0
    private var modelContext: ModelContext?
    private var currentSession: FocusSession?
    private var initialDuration: Int = 0 // 保存初始时长，用于重置
    private var originalDndState: Bool = false // 保存原始勿扰模式状态
    
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
        initialDuration = selectedDuration // 保存初始时长
        totalSeconds = selectedDuration * 60
        remainingSeconds = totalSeconds
        startTime = Date()
        accumulatedPauseTime = 0
        isRunning = true
        isPaused = false
        
        // 启用勿扰模式（如果设置中启用）
        let settings = SettingsManager.shared
        if settings.focusDndEnabled {
            enableDndMode()
        }
        
        // 播放白噪音（如果设置中启用）
        if settings.whiteNoiseEnabled && settings.selectedWhiteNoise != "none" {
            WhiteNoiseManager.shared.play(noiseTypeString: settings.selectedWhiteNoise)
            WhiteNoiseManager.shared.setVolume(settings.whiteNoiseVolume)
        }
        
        // 创建专注记录（立即插入到 context，这样在完成时只需要更新）
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
            isCompleted: false, // 明确设置为 false
            device: .ios
        )
        
        // 立即插入到 context，这样在完成时只需要更新属性
        if let context = modelContext {
            context.insert(currentSession!)
            // 处理待处理的更改
            context.processPendingChanges()
            // 保存初始状态
            try? context.save()
        }
        
        // 发送开始通知
        NotificationManager.shared.sendFocusStartNotification(duration: selectedDuration)
        
        // 启动 Live Activity（锁屏显示倒计时）- 根据设置决定是否启用
        if settings.liveActivityEnabled, let sessionId = currentSession?.id.uuidString {
            // 获取任务的图标和颜色（从标签中获取）
            var taskIcon: String? = nil
            var taskColor: String? = nil
            
            if let task = selectedTask, let firstTagName = task.tags.first, let context = modelContext {
                let tagDescriptor = FetchDescriptor<Tag>(
                    predicate: #Predicate<Tag> { tag in
                        tag.name == firstTagName
                    }
                )
                if let tag = try? context.fetch(tagDescriptor).first {
                    taskIcon = tag.icon
                    taskColor = tag.color
                }
            }
            
            // 如果没有找到标签，使用默认值
            if taskIcon == nil {
                taskIcon = "timer"
            }
            if taskColor == nil {
                taskColor = "#007AFF"
            }
            
            // 更新缓存
            cachedTaskIcon = taskIcon
            cachedTaskColor = taskColor
            cachedTaskId = selectedTask?.id
            
            LiveActivityManager.shared.startActivity(
                sessionId: sessionId,
                startTime: startTime!,
                totalSeconds: totalSeconds,
                taskName: selectedTask?.name,
                taskIcon: taskIcon,
                taskColor: taskColor
            )
        }
        
        // [已注释] 启用应用锁定（如果设置中启用）
        // 由于iOS系统限制，应用屏蔽功能暂时禁用
        /*
        if settings.focusLockEnabled {
            AppLockManager.shared.enableLocking(
                blockedApps: settings.blockedApps,
                blockAllAppsExceptSystem: settings.blockAllAppsExceptSystem
            )
        }
        */
        
        startTimer()
        Logger.info("开始专注: \(selectedDuration)分钟", category: .timer)
    }
    
    /// 暂停专注
    func pauseFocus() {
        guard isRunning && !isPaused else { return }
        
        // 更新 Live Activity（暂停状态）
        updateLiveActivity(isPaused: true)
        
        pausedTime = Date()
        isPaused = true
        timer?.invalidate()
        timer = nil
        
        Logger.info("暂停专注", category: .timer)
    }
    
    /// 恢复专注
    func resumeFocus() {
        guard isPaused else { return }
        
            // 更新 Live Activity（恢复状态）
            updateLiveActivity(isPaused: false)
        
        if let pausedTime = pausedTime {
            let pauseDuration = Date().timeIntervalSince(pausedTime)
            accumulatedPauseTime += pauseDuration
        }
        
        pausedTime = nil
        isPaused = false
        startTimer()
        
        Logger.info("恢复专注", category: .timer)
    }
    
    /// 重置专注（将时间重置为初始值并自动暂停）
    func resetFocus() {
        guard isRunning else { return }
        
        // 在重置前，先保存当前的专注时长（如果 >= 1分钟）
        if let session = currentSession, let context = modelContext {
            let endTime = Date()
            let totalElapsed = endTime.timeIntervalSince(session.startTime)
            let actualSeconds = Int(totalElapsed - accumulatedPauseTime)
            let actualMinutes = actualSeconds / 60
            
            // 如果专注时长超过1分钟，保存并标记为完成
            if actualMinutes >= 1 {
                // 删除旧的 session（isCompleted=false）
                context.delete(session)
                
                // 创建新的完成 session（isCompleted=true）
                let completedSession = FocusSession(
                    id: session.id,
                    userId: session.userId,
                    startTime: session.startTime,
                    endTime: endTime,
                    duration: actualSeconds,
                    plannedDuration: session.plannedDuration,
                    type: session.type,
                    mode: session.mode,
                    taskId: session.taskId,
                    taskName: session.taskName,
                    tags: session.tags,
                    notes: session.notes,
                    pauseCount: session.pauseCount,
                    interruptionCount: session.interruptionCount,
                    isCompleted: true,
                    device: session.device,
                    deviceModel: session.deviceModel,
                    syncStatus: .pending,
                    createdAt: session.createdAt,
                    updatedAt: Date()
                )
                
                context.insert(completedSession)
                
                // 更新用户统计
                StatisticsUtils.updateUserStatistics(
                    context: context,
                    focusMinutes: actualMinutes,
                    userId: completedSession.userId
                )
                
                // 如果关联了任务，更新任务进度
                if let taskId = completedSession.taskId {
                    updateTaskProgress(taskId: taskId, minutes: actualMinutes, context: context)
                }
                
                do {
                    try context.save()
                    print("✅ [FocusViewModel] 重置前保存专注记录: duration=\(actualSeconds)秒(\(actualMinutes)分钟), isCompleted=true")
                    
                    // 发送通知
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NotificationCenter.default.post(name: NSNotification.Name("FocusSessionCompleted"), object: nil)
                    }
                } catch {
                    Logger.error("重置前保存专注记录失败: \(error.localizedDescription)", category: .data)
                }
                
                // 创建新的 session 用于重置后的继续专注
                currentSession = FocusSession(
                    userId: session.userId,
                    startTime: Date(),
                    plannedDuration: initialDuration * 60,
                    type: session.type,
                    mode: session.mode,
                    taskId: session.taskId,
                    taskName: session.taskName,
                    tags: session.tags,
                    isCompleted: false,
                    device: session.device
                )
                context.insert(currentSession!)
            } else {
                // 如果专注时长少于1分钟，只更新当前 session，不保存
                // 创建新的 session 用于重置后的继续专注
                currentSession = FocusSession(
                    userId: session.userId,
                    startTime: Date(),
                    plannedDuration: initialDuration * 60,
                    type: session.type,
                    mode: session.mode,
                    taskId: session.taskId,
                    taskName: session.taskName,
                    tags: session.tags,
                    isCompleted: false,
                    device: session.device
                )
                context.insert(currentSession!)
                
                // 删除旧的 session（因为时长少于1分钟，不保存）
                context.delete(session)
                
                do {
                    try context.save()
                    print("✅ [FocusViewModel] 重置前清理专注记录: duration=\(actualSeconds)秒(\(actualMinutes)分钟), 少于1分钟不保存")
                } catch {
                    Logger.error("重置前清理专注记录失败: \(error.localizedDescription)", category: .data)
                }
            }
        }
        
        // 暂停计时器
        timer?.invalidate()
        timer = nil
        
        // 重置时间到初始值
        remainingSeconds = initialDuration * 60
        totalSeconds = initialDuration * 60
        accumulatedPauseTime = 0
        pausedTime = nil
        startTime = Date() // 重置开始时间
        
        // 自动暂停
        isPaused = true
        
        Logger.info("重置专注时间并暂停", category: .timer)
    }
    
    /// 停止专注
    func stopFocus() {
        // 立即停止计时器，避免继续更新
        timer?.invalidate()
        timer = nil
        
        // 立即清除UI状态，让用户感觉响应快
        isRunning = false
        isPaused = false
        remainingSeconds = 0
        totalSeconds = 0
        startTime = nil
        pausedTime = nil
        accumulatedPauseTime = 0
        initialDuration = 0
        
        // 清除休息状态
        isBreakTime = false
        breakRemainingSeconds = 0
        breakTotalSeconds = 0
        showBreakCompletion = false
        
        // 立即停止 Live Activity（在后台线程执行，避免阻塞）- 根据设置决定
        let settings = SettingsManager.shared
        if settings.liveActivityEnabled {
            _Concurrency.Task { @MainActor in
                LiveActivityManager.shared.stopActivity()
            }
        }
        
        // 停止白噪音（立即执行，不阻塞）
        WhiteNoiseManager.shared.stop()
        
        // 保存数据到后台线程执行
        if let session = currentSession {
            let endTime = Date()
            let totalElapsed = endTime.timeIntervalSince(session.startTime)
            let actualSeconds = Int(totalElapsed - accumulatedPauseTime)
            let actualMinutes = actualSeconds / 60
            let shouldComplete = actualMinutes >= 1
            let sessionId = session.id
            let taskId = session.taskId
            let userId = session.userId
            
            // 在后台线程保存数据
            _Concurrency.Task.detached { [weak self] in
                // 等待一小段时间，确保UI已经更新
                try? await _Concurrency.Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    // 在主线程访问ModelContext
                    guard let context = self.modelContext else { return }
                    
                    let descriptor = FetchDescriptor<FocusSession>(
                        predicate: #Predicate<FocusSession> { $0.id == sessionId }
                    )
                    
                    if let session = try? context.fetch(descriptor).first {
                        session.endTime = endTime
                        session.duration = actualSeconds
                        session.isCompleted = shouldComplete
                        session.updatedAt = Date()
                        session.syncStatus = .pending
                        
                        do {
                            try context.save()
                            print("✅ [FocusViewModel] 保存停止记录成功: isCompleted=\(shouldComplete), duration=\(actualSeconds)秒")
                            
                            if shouldComplete {
                                // 更新用户统计
                                StatisticsUtils.updateUserStatistics(
                                    context: context,
                                    focusMinutes: actualMinutes,
                                    userId: userId
                                )
                                
                                // 更新任务进度
                                if let taskId = taskId {
                                    self.updateTaskProgress(taskId: taskId, minutes: actualMinutes, context: context)
                                }
                                
                                // 发送通知
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    NotificationCenter.default.post(name: NSNotification.Name("FocusSessionCompleted"), object: nil)
                                }
                            }
                        } catch {
                            Logger.error("保存停止记录失败: \(error.localizedDescription)", category: .data)
                        }
                    }
                }
            }
        }
        
        // 清除当前session引用和缓存
        currentSession = nil
        cachedTaskIcon = nil
        cachedTaskColor = nil
        cachedTaskId = nil
        lastLiveActivityUpdate = nil
        
        Logger.info("停止专注", category: .timer)
    }
    
    /// 延长专注时间
    func extendDuration(minutes: Int) {
        guard isRunning else { return }
        remainingSeconds += minutes * 60
        totalSeconds += minutes * 60
    }
    
    // MARK: - Private Methods
    
    // 缓存任务图标和颜色，避免每次更新都查询数据库
    private var cachedTaskIcon: String? = nil
    private var cachedTaskColor: String? = nil
    private var cachedTaskId: UUID? = nil
    
    /// 更新 Live Activity（辅助方法）
    private func updateLiveActivity(isPaused: Bool) {
        // 只在任务改变时更新缓存，避免每次更新都查询数据库
        var taskIcon: String? = cachedTaskIcon
        var taskColor: String? = cachedTaskColor
        
        if let task = selectedTask, task.id != cachedTaskId {
            // 任务改变了，更新缓存
            if let firstTagName = task.tags.first, let context = modelContext {
                let tagDescriptor = FetchDescriptor<Tag>(
                    predicate: #Predicate<Tag> { tag in
                        tag.name == firstTagName
                    }
                )
                if let tag = try? context.fetch(tagDescriptor).first {
                    taskIcon = tag.icon
                    taskColor = tag.color
                    cachedTaskIcon = taskIcon
                    cachedTaskColor = taskColor
                    cachedTaskId = task.id
                }
            }
        }
        
        // 如果没有找到标签，使用默认值
        if taskIcon == nil {
            taskIcon = "timer"
        }
        if taskColor == nil {
            taskColor = "#007AFF"
        }
        
        // 根据设置决定是否更新 Live Activity
        let settings = SettingsManager.shared
        guard settings.liveActivityEnabled else { return }
        
        let seconds = isBreakTime ? breakRemainingSeconds : remainingSeconds
        LiveActivityManager.shared.updateActivity(
            remainingSeconds: seconds,
            isPaused: isPaused,
            taskName: selectedTask?.name,
            taskIcon: taskIcon,
            taskColor: taskColor
        )
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            // 使用 _Concurrency.Task 确保在主 actor 上执行（避免与 SwiftData 的 Task 模型冲突）
            _Concurrency.Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        // 使用 .common mode 确保在用户交互时 Timer 也能运行
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private var lastLiveActivityUpdate: Date?
    private let liveActivityUpdateInterval: TimeInterval = 1.0 // 每秒更新一次
    
    private func tick() {
        guard isRunning && !isPaused else { return }
        
        if remainingSeconds > 0 {
            remainingSeconds -= 1
            
            // 每秒更新 Live Activity
            let now = Date()
            if lastLiveActivityUpdate == nil || now.timeIntervalSince(lastLiveActivityUpdate!) >= liveActivityUpdateInterval {
                lastLiveActivityUpdate = now
                updateLiveActivity(isPaused: false)
            }
        } else {
            completeFocus()
        }
    }
    
    private func completeFocus() {
        // 计算实际专注时长（分钟）
        let endTime = Date()
        var actualDuration = selectedDuration
        
        // 保存专注记录
        if let oldSession = currentSession, let context = modelContext {
            // 计算实际经过的时间（秒），考虑暂停时间
            let totalElapsed = endTime.timeIntervalSince(oldSession.startTime)
            let actualSeconds = Int(totalElapsed - accumulatedPauseTime)
            // 计算实际专注时长（分钟）
            actualDuration = max(1, actualSeconds / 60) // 至少1分钟
            
            // 删除旧的 session（isCompleted=false）
            context.delete(oldSession)
            
            // 创建新的完成 session（isCompleted=true）
            let completedSession = FocusSession(
                id: oldSession.id,
                userId: oldSession.userId,
                startTime: oldSession.startTime,
                endTime: endTime,
                duration: actualSeconds,
                plannedDuration: oldSession.plannedDuration,
                type: oldSession.type,
                mode: oldSession.mode,
                taskId: oldSession.taskId,
                taskName: oldSession.taskName,
                tags: oldSession.tags,
                notes: oldSession.notes,
                pauseCount: oldSession.pauseCount,
                interruptionCount: oldSession.interruptionCount,
                isCompleted: true, // 确保设置为 true
                device: oldSession.device,
                deviceModel: oldSession.deviceModel,
                syncStatus: .pending,
                createdAt: oldSession.createdAt,
                updatedAt: Date()
            )
            
            print("✅ [FocusViewModel] 创建完成 session: id=\(completedSession.id), isCompleted=\(completedSession.isCompleted), duration=\(completedSession.duration)秒")
            
            // 插入新的完成 session（这样 @Query 能检测到变化）
            do {
                // 插入新的 session
                context.insert(completedSession)
                
                // 处理待处理的更改
                context.processPendingChanges()
                
                // 保存
                try context.save()
                print("✅ [FocusViewModel] 保存专注记录成功: \(completedSession.id), 实际时长: \(actualDuration)分钟")
                print("✅ [FocusViewModel] 保存后验证: session.isCompleted=\(completedSession.isCompleted), duration=\(completedSession.duration)秒")
                Logger.info("保存专注记录成功: \(completedSession.id), 实际时长: \(actualDuration)分钟", category: .data)
                
                // 立即更新用户统计数据（使用实际时长）
                StatisticsUtils.updateUserStatistics(
                    context: context,
                    focusMinutes: actualDuration,
                    userId: completedSession.userId
                )
                print("✅ [FocusViewModel] 用户统计更新完成")
                
                // 如果关联了任务，更新任务进度
                if let taskId = completedSession.taskId {
                    updateTaskProgress(taskId: taskId, minutes: actualDuration, context: context)
                }
                
                // 处理待处理的更改
                context.processPendingChanges()
                
                // 最终保存
                try context.save()
                print("✅ [FocusViewModel] 最终保存完成")
                print("✅ [FocusViewModel] 最终验证: session.isCompleted=\(completedSession.isCompleted), duration=\(completedSession.duration)秒")
                
                // 延迟发送通知，确保数据已保存并让 @Query 有时间检测变化
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("📢 [FocusViewModel] 发送 FocusSessionCompleted 通知")
                    NotificationCenter.default.post(name: NSNotification.Name("FocusSessionCompleted"), object: nil)
                }
            } catch {
                print("❌ [FocusViewModel] 保存专注记录失败: \(error.localizedDescription)")
                Logger.error("保存专注记录失败: \(error.localizedDescription)", category: .data)
            }
        }
        
        // 保存完成信息用于动画显示
        lastCompletedDuration = actualDuration
        
        stopFocus()
        currentSession = nil
        
        // 禁用勿扰模式
        disableDndMode()
        
        // 停止 Live Activity
        LiveActivityManager.shared.stopActivity()
        
        // [已注释] 禁用应用锁定
        // 由于iOS系统限制，应用屏蔽功能暂时禁用
        // AppLockManager.shared.disableLocking()
        
        // 停止白噪音
        WhiteNoiseManager.shared.stop()
        
        // 播放完成声音
        SoundManager.shared.playFocusCompleteSound()
        
        // 发送完成通知
        NotificationManager.shared.sendFocusCompleteNotification(
            duration: actualDuration,
            taskName: selectedTask?.name
        )
        
        // 自动进入休息
        startBreak()
        
        Logger.info("专注完成: \(actualDuration)分钟", category: .timer)
    }
    
        // MARK: - 任务进度更新
        private func updateTaskProgress(taskId: UUID, minutes: Int, context: ModelContext) {
            // 直接使用 UUID 比较（SwiftData 不支持嵌套 KeyPath）
            let descriptor = FetchDescriptor<Task>(
                predicate: #Predicate<Task> { task in
                    task.id == taskId
                }
            )
            
            if let task = try? context.fetch(descriptor).first {
                task.updateProgress(minutes: minutes)
                do {
                    try context.save()
                    Logger.info("更新任务进度成功: \(task.name), 进度: \(task.progress)/\(task.totalGoal)分钟", category: .data)
                } catch {
                    Logger.error("更新任务进度失败: \(error.localizedDescription)", category: .data)
                }
            }
        }
    
    // MARK: - 休息功能
    /// 开始休息
    func startBreak() {
        let settings = SettingsManager.shared
        breakTotalSeconds = settings.breakDuration * 60
        breakRemainingSeconds = breakTotalSeconds
        isBreakTime = true
        showBreakCompletion = false
        
        // 开始休息计时器
        startBreakTimer()
        
        Logger.info("开始休息: \(settings.breakDuration)分钟", category: .timer)
    }
    
    /// 继续专注（休息后）
    func continueAfterBreak() {
        isBreakTime = false
        showBreakCompletion = false
        breakRemainingSeconds = 0
        breakTotalSeconds = 0
        
        // 重新开始专注（使用相同的时长和任务）
        startFocus()
    }
    
    /// 结束专注（休息后）
    func endAfterBreak() {
        isBreakTime = false
        showBreakCompletion = false
        breakRemainingSeconds = 0
        breakTotalSeconds = 0
        
        // 停止计时器
        timer?.invalidate()
        timer = nil
    }
    
    private func startBreakTimer() {
        timer?.invalidate()
        timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.breakTick()
            }
        }
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func breakTick() {
        guard isBreakTime else { return }
        
        if breakRemainingSeconds > 0 {
            breakRemainingSeconds -= 1
        } else {
            // 休息结束
            timer?.invalidate()
            timer = nil
            
            // 播放休息完成声音
            SoundManager.shared.playBreakCompleteSound()
            
            // 检查设置，决定是否自动开始新一轮专注
            let settings = SettingsManager.shared
            if settings.autoStartAfterBreak {
                // 自动开始新一轮专注
                continueAfterBreak()
            } else {
                // 显示"继续"和"退出"按钮
                showBreakCompletion = true
            }
            
            Logger.info("休息结束", category: .timer)
        }
    }
    
    // MARK: - 勿扰模式
    private func enableDndMode() {
        // 保存原始勿扰模式状态
        originalDndState = true
        
        // 注意：iOS 系统限制，应用无法直接控制系统的勿扰模式
        // 但我们可以通过发送通知提示用户在控制中心开启勿扰模式
        
        // 请求通知权限（如果还没有）
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                Logger.error("请求通知权限失败: \(error.localizedDescription)", category: .app)
            } else if granted {
                Logger.info("通知权限已授予", category: .app)
                // 延迟发送提示，让用户有时间看到
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.showDNDHint()
                }
            }
        }
        
        Logger.info("启用勿扰模式（提示用户手动开启）", category: .app)
    }
    
    private func showDNDHint() {
        // 发送一个本地通知，提示用户在控制中心开启勿扰模式
        let content = UNMutableNotificationContent()
        content.title = "专注模式"
        content.body = "请在控制中心开启勿扰模式以获得更好的专注体验"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        let request = UNNotificationRequest(
            identifier: "dnd_hint_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.error("发送勿扰模式提示失败: \(error.localizedDescription)", category: .app)
            } else {
                Logger.info("已发送勿扰模式提示", category: .app)
            }
        }
    }
    
    private func disableDndMode() {
        // 恢复勿扰模式状态
        originalDndState = false
        
        Logger.info("禁用勿扰模式", category: .app)
    }
    
    deinit {
        timer?.invalidate()
    }
}

