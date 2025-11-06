//
//  TaskUtils.swift
//  FocusFlow
//
//  任务工具类
//

import Foundation
import SwiftData

struct TaskUtils {
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
    
    /// 确保默认标签存在
    @MainActor
    private static func ensureDefaultTagExists(context: ModelContext, userId: String, tagName: String) {
        let tagDescriptor = FetchDescriptor<Tag>(
            predicate: #Predicate<Tag> { tag in
                tag.name == tagName && tag.userId == userId
            }
        )
        
        if let existingTag = try? context.fetch(tagDescriptor).first {
            // 标签已存在
            return
        }
        
        // 创建默认标签"专注"
        let defaultTag = Tag(
            userId: userId,
            name: tagName,
            color: "#007AFF",
            icon: nil,
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
    
    /// 确保默认任务存在（在删除所有数据后调用）
    @MainActor
    static func ensureDefaultTaskExists(context: ModelContext) -> Task? {
        return initializeDefaultTask(context: context)
    }
}

