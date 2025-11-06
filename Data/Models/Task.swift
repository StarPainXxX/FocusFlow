//
//  Task.swift
//  FocusFlow
//
//  任务模型
//

import Foundation
import SwiftData

@Model
final class Task {
    var id: UUID
    var userId: String
    var name: String
    var taskDescription: String? // 任务描述（不能使用description，因为@Model宏已占用）
    var totalGoal: Int // 目标时长（分钟）
    var progress: Int // 已完成时长（分钟）
    var priority: TaskPriority
    var status: TaskStatus
    var dueDate: Date?
    var tags: [String]
    var colorTag: String // HEX颜色
    var icon: String?
    var parentTaskId: UUID?
    var order: Int
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    
    // 计算属性：进度百分比
    var progressPercentage: Double {
        guard totalGoal > 0 else { return 0 }
        return min(Double(progress) / Double(totalGoal), 1.0)
    }
    
    // 计算属性：是否过期
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return status != .done && Date() > dueDate
    }
    
    // 计算属性：是否完成（兼容性）
    var isCompleted: Bool {
        return status == .done
    }
    
    init(
        id: UUID = UUID(),
        userId: String,
        name: String,
        taskDescription: String? = nil,
        totalGoal: Int,
        progress: Int = 0,
        priority: TaskPriority = .medium,
        status: TaskStatus = .todo,
        dueDate: Date? = nil,
        tags: [String] = [],
        colorTag: String = "#007AFF",
        icon: String? = nil,
        parentTaskId: UUID? = nil,
        order: Int = 0,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.taskDescription = taskDescription
        self.totalGoal = totalGoal
        self.progress = progress
        self.priority = priority
        self.status = status
        self.dueDate = dueDate
        self.tags = tags
        self.colorTag = colorTag
        self.icon = icon
        self.parentTaskId = parentTaskId
        self.order = order
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
    }
    
    /// 标记为完成
    func markAsCompleted() {
        self.status = .done
        self.completedAt = Date()
        self.updatedAt = Date()
    }
    
    /// 更新进度
    func updateProgress(minutes: Int) {
        self.progress = min(progress + minutes, totalGoal)
        self.updatedAt = Date()
        
        // 根据进度自动更新状态
        let progressPercentage = self.progressPercentage
        
        if progressPercentage >= 1.0 {
            // 进度达到100%，标记为已完成
            if status != .done {
                markAsCompleted()
            }
        } else if progress > 0 {
            // 进度大于0，从待办转为进行中
            if status == .todo {
                self.status = .doing
            }
        } else {
            // 进度为0，从进行中转为待办
            if status == .doing {
                self.status = .todo
            }
        }
    }
}

// MARK: - 枚举类型

enum TaskPriority: String, Codable, CaseIterable {
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var displayName: String {
        switch self {
        case .high:
            return "高"
        case .medium:
            return "中"
        case .low:
            return "低"
        }
    }
}

enum TaskStatus: String, Codable {
    case todo = "todo"
    case doing = "doing"
    case done = "done"
}

