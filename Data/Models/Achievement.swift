//
//  Achievement.swift
//  FocusFlow
//
//  成就模型
//

import Foundation
import SwiftData

@Model
final class Achievement {
    var id: UUID
    var userId: String
    var achievementType: AchievementType
    var name: String
    var achievementDescription: String // 成就描述（不能使用description，因为@Model宏已占用）
    var icon: String
    var requirement: String // JSON字符串存储达成条件
    var isUnlocked: Bool
    var unlockedAt: Date?
    var level: Int
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        userId: String,
        achievementType: AchievementType,
        name: String,
        achievementDescription: String,
        icon: String,
        requirement: String,
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil,
        level: Int = 1,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.achievementType = achievementType
        self.name = name
        self.achievementDescription = achievementDescription
        self.icon = icon
        self.requirement = requirement
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
        self.level = level
        self.createdAt = createdAt
    }
    
    /// 解锁成就
    func unlock() {
        guard !isUnlocked else { return }
        self.isUnlocked = true
        self.unlockedAt = Date()
    }
}

// MARK: - 枚举类型

enum AchievementType: String, Codable {
    case duration = "duration" // 时长成就
    case streak = "streak" // 连续成就
    case pomodoro = "pomodoro" // 番茄成就
    case special = "special" // 特殊成就
}

