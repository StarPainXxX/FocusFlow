//
//  AppLockManager.swift
//  FocusFlow
//
//  应用锁定管理器（专注锁定模式 - 硬锁定）
//  [已注释] 由于iOS系统限制，应用屏蔽功能暂时禁用
//

/*
import Foundation
import UIKit
import Combine
import UserNotifications

// 类型别名以避免与 Task 模型类冲突
typealias AsyncTask = _Concurrency.Task

@MainActor
class AppLockManager: ObservableObject {
    static let shared = AppLockManager()
    
    private var isLockingEnabled = false
    private var blockedApps: [String] = []
    private var blockAllAppsExceptSystem: Bool = false
    nonisolated(unsafe) private var notificationObserver: NSObjectProtocol?
    
    // 系统应用Bundle ID前缀（iOS系统应用通常以这些开头）
    private let systemAppPrefixes = [
        "com.apple.",
        "com.apple.mobilephone",
        "com.apple.mobilemail",
        "com.apple.mobilesafari",
        "com.apple.calculator",
        "com.apple.camera",
        "com.apple.mobiletimer",
        "com.apple.mobilecal",
        "com.apple.mobilenotes",
        "com.apple.mobilemaps"
    ]
    
    private init() {
        setupAppStateObserver()
    }
    
    deinit {
        // 在 deinit 中直接移除观察者（不需要 MainActor）
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    /// 启用应用锁定（硬锁定）
    func enableLocking(
        blockedApps: [String],
        blockAllAppsExceptSystem: Bool
    ) {
        isLockingEnabled = true
        self.blockedApps = blockedApps
        self.blockAllAppsExceptSystem = blockAllAppsExceptSystem
        
        // 请求通知权限（如果还没有）
        requestNotificationPermission()
        
        Logger.info("应用锁定已启用（硬锁定）", category: .app)
        Logger.info("屏蔽应用列表: \(blockedApps)", category: .app)
        Logger.info("屏蔽所有应用（除系统）: \(blockAllAppsExceptSystem)", category: .app)
    }
    
    /// 请求通知权限
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                Logger.error("请求通知权限失败: \(error.localizedDescription)", category: .app)
            } else if granted {
                Logger.info("通知权限已授予", category: .app)
            } else {
                Logger.info("通知权限被拒绝", category: .app)
            }
        }
    }
    
    /// 禁用应用锁定
    func disableLocking() {
        isLockingEnabled = false
        stopBackgroundMonitoring()
        Logger.info("应用锁定已禁用", category: .app)
    }
    
    /// 检查应用是否应该被锁定
    func shouldBlockApp(bundleId: String) -> Bool {
        guard isLockingEnabled else { return false }
        
        // 检查是否是系统应用
        if isSystemApp(bundleId: bundleId) {
            return false
        }
        
        // 如果启用"屏蔽所有应用（除了系统应用）"
        if blockAllAppsExceptSystem {
            return true
        }
        
        // 检查是否在自定义屏蔽列表中
        return blockedApps.contains(bundleId)
    }
    
    /// 检查是否是系统应用
    private func isSystemApp(bundleId: String) -> Bool {
        return systemAppPrefixes.contains { bundleId.hasPrefix($0) }
    }
    
    /// 设置应用状态观察者
    private func setupAppStateObserver() {
        // 监听应用进入后台（多个通知）
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            // 由于回调已经在主队列，直接创建 Task
            AsyncTask { @MainActor in
                await self.handleAppWillResignActive()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            // 由于回调已经在主队列，直接创建 Task
            AsyncTask { @MainActor in
                await self.handleAppDidEnterBackground()
            }
        }
    }
    
    /// 移除应用状态观察者
    private func removeAppStateObserver() {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    /// 处理应用即将进入后台
    private func handleAppWillResignActive() async {
        guard isLockingEnabled else { return }
        
        // 立即发送通知提醒
        await showBlockedAppAlert()
        
        // 尝试立即将应用带回前台
        attemptToBringAppToForeground()
    }
    
    /// 处理应用已进入后台
    private func handleAppDidEnterBackground() async {
        guard isLockingEnabled else { return }
        
        // 应用已进入后台，立即发送通知
        await showBlockedAppAlert()
        
        // 尝试将应用带回前台
        attemptToBringAppToForeground()
        
        // 持续检测并发送通知
        startBackgroundMonitoring()
    }
    
    /// 尝试将应用带回前台
    private func attemptToBringAppToForeground() {
        // 注意：iOS系统限制，无法直接切换应用或阻止用户切换到其他应用
        // 我们只能通过通知提醒用户返回应用
        
        // 尝试通过URL scheme打开应用（如果应用支持）
        // 注意：这需要应用配置URL scheme，并且需要应用支持该scheme
        // 由于iOS限制，即使应用支持URL scheme，也无法强制切换回应用
        // 这里只是尝试，实际效果取决于系统权限
        
        Logger.info("尝试将应用带回前台（受iOS系统限制）", category: .app)
        
        // 由于iOS限制，我们无法真正阻止应用切换
        // 只能通过频繁的通知提醒用户
    }
    
    /// 开始后台监控
    private var backgroundMonitoringTimer: Timer?
    
    private func startBackgroundMonitoring() {
        // 停止现有的监控
        stopBackgroundMonitoring()
        
        // 每3秒检测一次应用状态并发送通知
        // 注意：过于频繁的通知可能会被系统限制
        backgroundMonitoringTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            // 使用 Task 处理 async 方法
            AsyncTask { @MainActor in
                guard await self.isLockingEnabled else {
                    timer.invalidate()
                    await self.stopBackgroundMonitoring()
                    return
                }
                
                // 注意：当应用在后台时，Timer可能无法正常运行
                // 这是iOS的限制，后台任务执行时间有限
                
                if UIApplication.shared.applicationState == .background {
                    // 应用仍在后台，继续发送通知提醒
                    await self.showBlockedAppAlert()
                    self.attemptToBringAppToForeground()
                } else {
                    // 应用已回到前台，停止监控
                    timer.invalidate()
                    await self.stopBackgroundMonitoring()
                }
            }
        }
        
        // 将Timer添加到RunLoop的common模式，以便在后台也能运行
        if let timer = backgroundMonitoringTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    /// 停止后台监控
    private func stopBackgroundMonitoring() {
        backgroundMonitoringTimer?.invalidate()
        backgroundMonitoringTimer = nil
    }
    
    /// 显示被屏蔽应用提醒
    private func showBlockedAppAlert() async {
        // 发送本地通知提醒用户（使用立即触发的通知）
        let content = UNMutableNotificationContent()
        content.title = "专注模式"
        content.body = "专注期间无法使用其他应用，请返回专注应用"
        content.sound = .default
        content.categoryIdentifier = "APP_BLOCKED"
        content.userInfo = ["type": "app_blocked"]
        
        // 使用立即触发的通知
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "app_blocked_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            Logger.info("已发送应用屏蔽提醒", category: .app)
        } catch {
            Logger.error("发送应用屏蔽通知失败: \(error.localizedDescription)", category: .app)
        }
    }
}
*/

// MARK: - 应用屏蔽功能已暂时禁用（由于iOS系统限制）
// 如需恢复，请取消注释上面的代码
