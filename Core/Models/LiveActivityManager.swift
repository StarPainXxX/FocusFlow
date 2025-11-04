//
//  LiveActivityManager.swift
//  FocusFlow
//
//  Live Activity 管理工具（用于锁屏显示倒计时）
//

import Foundation
import ActivityKit
import WidgetKit

@MainActor
class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<FocusActivityAttributes>?
    private var hasLoggedUpdateFailure = false // 避免重复打印更新失败日志
    
    private init() {}
    
    /// 启动 Live Activity
    func startActivity(
        sessionId: String,
        startTime: Date,
        totalSeconds: Int,
        taskName: String?,
        taskIcon: String? = nil,
        taskColor: String? = nil
    ) {
        // 检查是否支持 Live Activity
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            Logger.info("Live Activity 未启用", category: .app)
            return
        }
        
        // 停止现有的 Activity（如果有）
        stopActivity()
        
        let attributes = FocusActivityAttributes(
            sessionId: sessionId,
            startTime: startTime
        )
        
        let initialState = FocusActivityAttributes.ContentState(
            remainingSeconds: totalSeconds,
            totalSeconds: totalSeconds,
            taskName: taskName,
            taskIcon: taskIcon,
            taskColor: taskColor,
            isPaused: false
        )
        
        do {
            // 创建 ActivityContent，包含 UI 配置
            let activityContent = ActivityContent(
                state: initialState,
                staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date())
            )
            
            // 请求启动 Live Activity
            let activity = try Activity<FocusActivityAttributes>.request(
                attributes: attributes,
                content: activityContent,
                pushType: nil
            )
            
            currentActivity = activity
            hasLoggedUpdateFailure = false // 重置标志
            Logger.info("Live Activity 已启动: \(sessionId)", category: .app)
            Logger.info("Live Activity 任务信息 - 名称: \(taskName ?? "无"), 图标: \(taskIcon ?? "无"), 颜色: \(taskColor ?? "无")", category: .app)
        } catch {
            Logger.error("启动 Live Activity 失败: \(error.localizedDescription)", category: .app)
            Logger.error("提示：请在 Xcode 项目设置中添加 NSSupportsLiveActivities = YES", category: .app)
            // 启动失败时，清空 currentActivity，避免后续更新尝试
            currentActivity = nil
            hasLoggedUpdateFailure = true // 设置标志，避免重复打印更新失败日志
        }
    }
    
    /// 更新 Live Activity
    func updateActivity(
        remainingSeconds: Int,
        isPaused: Bool,
        taskName: String?,
        taskIcon: String? = nil,
        taskColor: String? = nil
    ) {
        guard let activity = currentActivity else {
            // 只在第一次失败时打印日志，避免重复打印
            if !hasLoggedUpdateFailure {
                Logger.info("无法更新 Live Activity：当前没有活动的 Activity（可能是 Live Activity 未启动或已停止）", category: .app)
                hasLoggedUpdateFailure = true
            }
            return
        }
        
        // 重置标志，因为 Activity 存在
        hasLoggedUpdateFailure = false
        
        let updatedState = FocusActivityAttributes.ContentState(
            remainingSeconds: remainingSeconds,
            totalSeconds: activity.content.state.totalSeconds,
            taskName: taskName,
            taskIcon: taskIcon ?? activity.content.state.taskIcon,
            taskColor: taskColor ?? activity.content.state.taskColor,
            isPaused: isPaused
        )
        
        let activityContent = ActivityContent(
            state: updatedState,
            staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date())
        )
        
        _Concurrency.Task { @MainActor in
            await activity.update(activityContent)
        }
    }
    
    /// 停止 Live Activity
    func stopActivity() {
        guard let activity = currentActivity else { return }
        
        let finalState = activity.content.state
        let finalContent = ActivityContent(
            state: finalState,
            staleDate: Calendar.current.date(byAdding: .minute, value: 1, to: Date())
        )
        
        _Concurrency.Task { @MainActor in
            await activity.end(finalContent, dismissalPolicy: .immediate)
            currentActivity = nil
            hasLoggedUpdateFailure = false // 重置标志
            Logger.info("Live Activity 已停止", category: .app)
        }
    }
}

