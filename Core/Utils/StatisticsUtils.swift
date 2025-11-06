//
//  StatisticsUtils.swift
//  FocusFlow
//
//  统计工具类
//

import Foundation
import SwiftData

struct StatisticsUtils {
    /// 计算连续专注天数
    static func calculateConsecutiveDays(from sessions: [FocusSession]) -> Int {
        // 获取所有完成的专注记录
        let completedSessions = sessions.filter { $0.isCompleted }
        guard !completedSessions.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        
        // 获取有专注记录的日期集合（去重并排序）
        let dates = Set(completedSessions.map { session in
            calendar.startOfDay(for: session.startTime)
        }).sorted(by: >) // 从今天开始倒序
        
        guard !dates.isEmpty else { return 0 }
        
        // 检查今天是否有专注记录
        let hasToday = dates.first.map { calendar.isDate($0, inSameDayAs: todayStart) } ?? false
        
        if !hasToday {
            // 如果今天没有专注记录，返回0
            return 0
        }
        
        // 从今天开始往前计算连续天数
        var consecutiveDays = 1
        
        for i in 1..<dates.count {
            let expectedDate = calendar.date(byAdding: .day, value: -i, to: todayStart)!
            let date = dates[i]
            
            if calendar.isDate(date, inSameDayAs: expectedDate) {
                consecutiveDays += 1
            } else {
                // 如果日期不连续，停止计算
                break
            }
        }
        
        return consecutiveDays
    }
    
    /// 更新用户统计数据
    @MainActor
    static func updateUserStatistics(
        context: ModelContext,
        focusMinutes: Int,
        userId: String = "default-user"
    ) {
        // 获取或创建用户
        // 先尝试查找所有用户，取第一个（单用户应用）
        let defaultDescriptor = FetchDescriptor<User>()
        var user: User?
        if let allUsers = try? context.fetch(defaultDescriptor), let firstUser = allUsers.first {
            user = firstUser
        }
        
        // 如果还是没有，创建新用户
        if user == nil {
            user = User()
            context.insert(user!)
        }
        
        // 确保 user 不为 nil
        guard let finalUser = user else {
            Logger.error("无法创建或获取用户", category: .data)
            return
        }
        
        // 更新专注时长
        finalUser.addFocusTime(focusMinutes)
        
        // 更新经验值（每分钟1经验）
        finalUser.addExp(focusMinutes * AppConstants.expPerMinute)
        
        // 获取所有完成的专注记录
        let sessionDescriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { $0.isCompleted == true }
        )
        
        if let allSessions = try? context.fetch(sessionDescriptor) {
            // 计算连续天数
            let consecutiveDays = calculateConsecutiveDays(from: allSessions)
            finalUser.updateConsecutiveDays(consecutiveDays)
        }
        
        // 保存
        do {
            try context.save()
            Logger.info("更新用户统计成功: 专注\(focusMinutes)分钟, 连续\(finalUser.consecutiveDays)天", category: .data)
            
            // 检查并解锁成就
            let sessionDescriptor = FetchDescriptor<FocusSession>(
                predicate: #Predicate { $0.isCompleted == true }
            )
            if let allSessions = try? context.fetch(sessionDescriptor) {
                checkAndUnlockAchievements(
                    context: context,
                    user: finalUser,
                    sessions: allSessions
                )
            }
        } catch {
            Logger.error("更新用户统计失败: \(error.localizedDescription)", category: .data)
        }
    }
    
    // MARK: - 成就检查（临时内联，直到 AchievementUtils 被添加到项目）
    /// 检查并解锁成就
    @MainActor
    private static func checkAndUnlockAchievements(
        context: ModelContext,
        user: User,
        sessions: [FocusSession]
    ) {
        let userId = user.id.uuidString
        
        let descriptor = FetchDescriptor<Achievement>(
            predicate: #Predicate { $0.userId == userId && $0.isUnlocked == false }
        )
        
        guard let achievements = try? context.fetch(descriptor) else { return }
        
        let completedSessions = sessions.filter { $0.isCompleted }
        let pomodoroSessions = completedSessions.filter { $0.type == .pomodoro && $0.mode == .work }
        
        for achievement in achievements {
            if checkAchievementRequirement(achievement, user: user, sessions: completedSessions, pomodoros: pomodoroSessions.count) {
                achievement.unlock()
                Logger.info("解锁成就: \(achievement.name)", category: .data)
                
                // 发送解锁通知
                NotificationManager.shared.sendAchievementUnlockedNotification(achievement: achievement)
            }
        }
        
        do {
            try context.save()
        } catch {
            Logger.error("保存成就状态失败: \(error.localizedDescription)", category: .data)
        }
    }
    
    /// 检查成就要求
    private static func checkAchievementRequirement(
        _ achievement: Achievement,
        user: User,
        sessions: [FocusSession],
        pomodoros: Int
    ) -> Bool {
        guard let requirementData = achievement.requirement.data(using: .utf8),
              let requirementDict = try? JSONSerialization.jsonObject(with: requirementData) as? [String: Any] else {
            return false
        }
        
        switch achievement.achievementType {
        case .duration:
            if let totalMinutes = requirementDict["totalMinutes"] as? Int {
                return user.totalFocusTime >= totalMinutes
            }
            
        case .streak:
            if let consecutiveDays = requirementDict["consecutiveDays"] as? Int {
                return user.consecutiveDays >= consecutiveDays
            }
            
        case .pomodoro:
            if let pomodoroCount = requirementDict["pomodoroCount"] as? Int {
                return pomodoros >= pomodoroCount
            }
            
        case .special:
            if let singleSessionMinutes = requirementDict["singleSessionMinutes"] as? Int {
                let maxSession = sessions.map { $0.duration / 60 }.max() ?? 0
                return maxSession >= singleSessionMinutes
            }
            
            if let earlyMorningMinutes = requirementDict["earlyMorningMinutes"] as? Int {
                let calendar = Calendar.current
                let earlyMorningSessions = sessions.filter { session in
                    let hour = calendar.component(.hour, from: session.startTime)
                    return hour >= 5 && hour < 7
                }
                let totalMinutes = earlyMorningSessions.reduce(0) { $0 + ($1.duration / 60) }
                return totalMinutes >= earlyMorningMinutes
            }
        }
        
        return false
    }
}

