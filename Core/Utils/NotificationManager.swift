//
//  NotificationManager.swift
//  FocusFlow
//
//  通知管理工具
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    /// 请求通知权限
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            Logger.error("请求通知权限失败: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 发送专注完成通知
    func sendFocusCompleteNotification(duration: Int, taskName: String?) {
        // 检查通知设置
        let settings = SettingsManager.shared
        guard settings.notificationsEnabled && settings.focusCompleteNotification else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "专注完成！"
        content.body = "你已专注 \(DateUtils.formatDuration(duration))"
        if let taskName = taskName {
            content.body += " - \(taskName)"
        }
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: AppConstants.NotificationID.focusComplete, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.error("发送通知失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 发送专注开始通知
    func sendFocusStartNotification(duration: Int) {
        // 检查通知设置
        let settings = SettingsManager.shared
        guard settings.notificationsEnabled && settings.focusStartNotification else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "专注开始"
        content.body = "专注 \(DateUtils.formatDuration(duration)) 分钟"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: AppConstants.NotificationID.focusStart, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.error("发送通知失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 发送成就解锁通知
    func sendAchievementUnlockedNotification(achievement: Achievement) {
        // 检查通知设置
        let settings = SettingsManager.shared
        guard settings.notificationsEnabled && settings.achievementNotification else { return }
        
        // 成就解锁通知可以突破免打扰时段
        let content = UNMutableNotificationContent()
        content.title = "🎉 成就解锁！"
        content.body = "恭喜获得「\(achievement.name)」成就"
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: "achievement_\(achievement.id.uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.error("发送成就通知失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 取消所有通知
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

