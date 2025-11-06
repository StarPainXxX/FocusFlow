//
//  Tag.swift
//  FocusFlow
//
//  标签模型
//

import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var userId: String
    var name: String
    var color: String // HEX颜色
    var icon: String?
    var usageCount: Int
    var isDefault: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        userId: String,
        name: String,
        color: String = "#007AFF",
        icon: String? = nil,
        usageCount: Int = 0,
        isDefault: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.color = color
        self.icon = icon
        self.usageCount = usageCount
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// 增加使用次数
    func incrementUsage() {
        self.usageCount += 1
        self.updatedAt = Date()
    }
}

// MARK: - 预设标签

extension Tag {
    static func defaultTags(userId: String) -> [Tag] {
        return [
            Tag(userId: userId, name: "学习", color: "#007AFF", isDefault: true),
            Tag(userId: userId, name: "工作", color: "#34C759", isDefault: true),
            Tag(userId: userId, name: "阅读", color: "#FF9500", isDefault: true),
            Tag(userId: userId, name: "编程", color: "#5856D6", isDefault: true),
            Tag(userId: userId, name: "写作", color: "#FF2D55", isDefault: true),
            Tag(userId: userId, name: "运动", color: "#FF3B30", isDefault: true)
        ]
    }
}

