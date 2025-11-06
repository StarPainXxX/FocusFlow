//
//  AchievementUtils.swift
//  FocusFlow
//
//  成就工具类
//

import Foundation
import SwiftData

struct AchievementUtils {
    /// 初始化默认成就
    @MainActor
    static func initializeDefaultAchievements(context: ModelContext, userId: String? = nil) {
        // 如果没有指定userId，尝试获取第一个用户，否则使用默认值
        let finalUserId: String
        if let userId = userId {
            finalUserId = userId
        } else {
            let userDescriptor = FetchDescriptor<User>()
            if let user = try? context.fetch(userDescriptor).first {
                finalUserId = user.id.uuidString
            } else {
                finalUserId = "default-user"
            }
        }
        
        // 检查是否已经存在成就，避免重复创建
        let existingAchievementsDescriptor = FetchDescriptor<Achievement>(
            predicate: #Predicate<Achievement> { achievement in
                achievement.userId == finalUserId
            }
        )
        if let existingAchievements = try? context.fetch(existingAchievementsDescriptor), !existingAchievements.isEmpty {
            // 如果已有成就，跳过初始化
            return
        }
        
        // 批量创建成就
        let achievements = [
            // 时长成就
            Achievement(
                userId: finalUserId,
                achievementType: .duration,
                name: "初出茅庐",
                achievementDescription: "累计专注10小时",
                icon: "flame.fill",
                requirement: "{\"totalMinutes\": 600}"
            ),
            Achievement(
                userId: finalUserId,
                achievementType: .duration,
                name: "小有所成",
                achievementDescription: "累计专注50小时",
                icon: "star.fill",
                requirement: "{\"totalMinutes\": 3000}"
            ),
            Achievement(
                userId: finalUserId,
                achievementType: .duration,
                name: "专注达人",
                achievementDescription: "累计专注100小时",
                icon: "crown.fill",
                requirement: "{\"totalMinutes\": 6000}"
            ),
            
            // 连续成就
            Achievement(
                userId: finalUserId,
                achievementType: .streak,
                name: "起步",
                achievementDescription: "连续专注3天",
                icon: "flame.fill",
                requirement: "{\"consecutiveDays\": 3}"
            ),
            Achievement(
                userId: finalUserId,
                achievementType: .streak,
                name: "坚持一周",
                achievementDescription: "连续专注7天",
                icon: "flame.fill",
                requirement: "{\"consecutiveDays\": 7}"
            ),
            Achievement(
                userId: finalUserId,
                achievementType: .streak,
                name: "月度坚持",
                achievementDescription: "连续专注30天",
                icon: "flame.fill",
                requirement: "{\"consecutiveDays\": 30}"
            ),
            
            // 番茄成就
            Achievement(
                userId: finalUserId,
                achievementType: .pomodoro,
                name: "番茄新人",
                achievementDescription: "完成10个番茄",
                icon: "timer",
                requirement: "{\"pomodoroCount\": 10}"
            ),
            Achievement(
                userId: finalUserId,
                achievementType: .pomodoro,
                name: "番茄达人",
                achievementDescription: "完成100个番茄",
                icon: "timer",
                requirement: "{\"pomodoroCount\": 100}"
            ),
            
            // 特殊成就
            Achievement(
                userId: finalUserId,
                achievementType: .special,
                name: "马拉松",
                achievementDescription: "单次专注超过3小时",
                icon: "figure.run",
                requirement: "{\"singleSessionMinutes\": 180}"
            ),
            Achievement(
                userId: finalUserId,
                achievementType: .special,
                name: "早起鸟",
                achievementDescription: "在05:00-07:00专注超过50小时",
                icon: "sunrise.fill",
                requirement: "{\"earlyMorningMinutes\": 3000}"
            )
        ]
        
        // 批量插入所有成就
        for achievement in achievements {
            context.insert(achievement)
        }
        
        // 一次性保存所有成就
        do {
            try context.save()
            Logger.info("初始化默认成就成功: \(achievements.count)个", category: .data)
        } catch {
            Logger.error("初始化默认成就失败: \(error.localizedDescription)", category: .data)
        }
    }
    
    /// 检查并解锁成就
    @MainActor
    static func checkAndUnlockAchievements(
        context: ModelContext,
        user: User,
        sessions: [FocusSession]
    ) {
        // 使用userId字符串而不是UUID
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
    
    // MARK: - 默认任务初始化（添加到此处以避免 TaskUtils 文件未添加到项目的问题）
    /// 初始化默认任务"专注"
    @MainActor
    static func initializeDefaultTask(context: ModelContext, userId: String? = nil) -> Task? {
        let finalUserId: String
        if let userId = userId {
            finalUserId = userId
        } else {
            let userDescriptor = FetchDescriptor<User>()
            if let user = try? context.fetch(userDescriptor).first {
                finalUserId = user.id.uuidString
            } else {
                finalUserId = "default-user"
            }
        }
        
        // 首先确保"专注"标签存在
        ensureDefaultTagExists(context: context, userId: finalUserId, tagName: "专注")
        
        // 检查是否已经存在默认任务"专注"
        let taskDescriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.name == "专注" && task.userId == finalUserId
            }
        )
        
        if let existingTask = try? context.fetch(taskDescriptor).first {
            // 如果已存在，确保它有"专注"标签
            if !existingTask.tags.contains("专注") {
                existingTask.tags = ["专注"]
                existingTask.updatedAt = Date()
                do {
                    try context.save()
                    Logger.info("更新默认任务标签成功", category: .data)
                } catch {
                    Logger.error("更新默认任务标签失败: \(error.localizedDescription)", category: .data)
                }
            }
            return existingTask
        }
        
        // 创建默认任务"专注"
        let defaultTask = Task(
            userId: finalUserId,
            name: "专注",
            taskDescription: "默认专注任务",
            totalGoal: 60, // 默认目标60分钟
            priority: .medium,
            status: .todo,
            dueDate: nil,
            tags: ["专注"],
            colorTag: "#007AFF",
            isArchived: false
        )
        
        context.insert(defaultTask)
        
        do {
            try context.save()
            Logger.info("初始化默认任务成功", category: .data)
            return defaultTask
        } catch {
            Logger.error("初始化默认任务失败: \(error.localizedDescription)", category: .data)
            return nil
        }
    }
    
    /// 初始化所有默认标签
    @MainActor
    static func initializeDefaultTags(context: ModelContext, userId: String? = nil) {
        let finalUserId: String
        if let userId = userId {
            finalUserId = userId
        } else {
            let userDescriptor = FetchDescriptor<User>()
            if let user = try? context.fetch(userDescriptor).first {
                finalUserId = user.id.uuidString
            } else {
                finalUserId = "default-user"
            }
        }
        
        // 获取所有默认标签配置（包括"专注"）：(名称, 颜色, icon)
        let defaultTagsConfig: [(String, String, String?)] = [
            ("专注", "#007AFF", "timer"),
            ("学习", "#007AFF", "book.fill"),
            ("工作", "#34C759", "briefcase.fill"),
            ("阅读", "#FF9500", "book.closed.fill"),
            ("编程", "#5856D6", "laptopcomputer"),
            ("写作", "#FF2D55", "pencil"),
            ("运动", "#FF3B30", "dumbbell.fill")
        ]
        
        // 批量检查哪些标签已存在，只创建不存在的标签
        let existingTagsDescriptor = FetchDescriptor<Tag>(
            predicate: #Predicate<Tag> { tag in
                tag.userId == finalUserId
            }
        )
        let existingTags = (try? context.fetch(existingTagsDescriptor)) ?? []
        let existingTagNames = Set(existingTags.map { $0.name })
        
        // 批量创建不存在的标签
        var tagsToInsert: [Tag] = []
        for (tagName, color, icon) in defaultTagsConfig {
            if !existingTagNames.contains(tagName) {
                let tag = Tag(
                    userId: finalUserId,
                    name: tagName,
                    color: color,
                    icon: icon,
                    isDefault: true
                )
                tagsToInsert.append(tag)
            }
        }
        
        // 批量插入
        if !tagsToInsert.isEmpty {
            for tag in tagsToInsert {
                context.insert(tag)
            }
            do {
                try context.save()
                Logger.info("初始化默认标签成功: \(tagsToInsert.count)个", category: .data)
            } catch {
                Logger.error("初始化默认标签失败: \(error.localizedDescription)", category: .data)
            }
        }
    }
    
    /// 确保默认标签存在
    @MainActor
    private static func ensureDefaultTagExists(context: ModelContext, userId: String, tagName: String, color: String = "#007AFF", icon: String? = nil) {
        let tagDescriptor = FetchDescriptor<Tag>(
            predicate: #Predicate<Tag> { tag in
                tag.name == tagName && tag.userId == userId
            }
        )
        
        if let existingTag = try? context.fetch(tagDescriptor).first {
            // 标签已存在，但更新icon（如果原来没有）
            if existingTag.icon == nil && icon != nil {
                existingTag.icon = icon
                existingTag.updatedAt = Date()
                do {
                    try context.save()
                    Logger.info("更新默认标签icon成功: \(tagName)", category: .data)
                } catch {
                    Logger.error("更新默认标签icon失败: \(error.localizedDescription)", category: .data)
                }
            }
            return
        }
        
        // 创建默认标签
        let defaultTag = Tag(
            userId: userId,
            name: tagName,
            color: color,
            icon: icon,
            usageCount: 0,
            isDefault: true
        )
        
        context.insert(defaultTag)
        
        do {
            try context.save()
            Logger.info("初始化默认标签成功: \(tagName)", category: .data)
        } catch {
            Logger.error("初始化默认标签失败: \(error.localizedDescription)", category: .data)
        }
    }
}

