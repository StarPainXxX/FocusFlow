//
//  TasksViewModel.swift
//  FocusFlow
//
//  任务视图模型
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class TasksViewModel: ObservableObject {
    @Published var selectedFilter: TaskFilter = .todo // 默认第一项是"待办"
    @Published var selectedSort: TaskSort = .priority
    @Published var showTaskForm = false
    @Published var editingTask: Task?
    @Published var viewMode: TaskViewMode = .list
    @Published var selectedCalendarMonth: Date? = Date()
    @Published var selectedCalendarDate: Date?
    
    var filteredTasks: [Task] {
        var tasks = allTasks
        
        // 应用筛选
        switch selectedFilter {
        case .all:
            break
        case .todo:
            // 待办：进度为0且状态为todo，且不是已过期
            let today = Calendar.current.startOfDay(for: Date())
            tasks = tasks.filter { task in
                let taskDay = Calendar.current.startOfDay(for: task.createdAt)
                return task.progress == 0 && task.status == .todo && taskDay >= today
            }
        case .inProgress:
            // 进行中：进度>0且<100%
            tasks = tasks.filter { $0.progress > 0 && $0.progressPercentage < 1.0 }
        case .done:
            // 已完成：状态为done或进度>=100%
            tasks = tasks.filter { $0.status == .done || $0.progressPercentage >= 1.0 }
        case .overdue:
            // 已过期：任务的日期（createdAt）在今天之前
            let today = Calendar.current.startOfDay(for: Date())
            tasks = tasks.filter { task in
                let taskDay = Calendar.current.startOfDay(for: task.createdAt)
                return taskDay < today
            }
        }
        
        // 应用排序
        switch selectedSort {
        case .priority:
            tasks.sort { $0.priority.rawValue > $1.priority.rawValue }
        case .dueDate:
            tasks.sort {
                if let date1 = $0.dueDate, let date2 = $1.dueDate {
                    return date1 < date2
                }
                return $0.dueDate != nil
            }
        case .created:
            tasks.sort { $0.createdAt > $1.createdAt }
        case .name:
            tasks.sort { $0.name < $1.name }
        }
        
        return tasks
    }
    
    var allTasks: [Task] = [] // 改为公开，供日历视图使用
    
    func updateTasks(_ tasks: [Task]) {
        // 过滤掉默认的"专注"任务，只显示自定义任务
        allTasks = tasks.filter { $0.name != "专注" }
    }
    
    func createTask(
        name: String,
        taskDescription: String?,
        totalGoal: Int,
        priority: TaskPriority,
        taskDate: Date, // 日期为必选项
        dueDate: Date?,
        tags: [String],
        context: ModelContext
    ) {
        let task = Task(
            userId: "default-user",
            name: name,
            taskDescription: taskDescription,
            totalGoal: totalGoal,
            priority: priority,
            dueDate: dueDate,
            tags: tags
        )
        // 设置创建日期为指定的taskDate
        task.createdAt = taskDate
        context.insert(task)
        do {
            try context.save()
        } catch {
            Logger.error("创建任务失败: \(error.localizedDescription)", category: .data)
        }
    }
    
    func updateTask(_ task: Task, context: ModelContext) {
        task.updatedAt = Date()
        do {
            try context.save()
        } catch {
            Logger.error("更新任务失败: \(error.localizedDescription)", category: .data)
        }
    }
    
    func deleteTask(_ task: Task, context: ModelContext) {
        context.delete(task)
        do {
            try context.save()
        } catch {
            Logger.error("删除任务失败: \(error.localizedDescription)", category: .data)
        }
    }
    
    // MARK: - 看板视图数据（使用与列表视图相同的筛选逻辑）
    var todoTasks: [Task] {
        // 待办：进度为0且状态为todo，且不是已过期
        let today = Calendar.current.startOfDay(for: Date())
        return allTasks.filter { task in
            let taskDay = Calendar.current.startOfDay(for: task.createdAt)
            return task.progress == 0 && task.status == .todo && taskDay >= today
        }
    }
    
    var doingTasks: [Task] {
        // 进行中：进度>0且<100%
        allTasks.filter { $0.progress > 0 && $0.progressPercentage < 1.0 }
    }
    
    var doneTasks: [Task] {
        // 已完成：状态为done或进度>=100%
        allTasks.filter { $0.status == .done || $0.progressPercentage >= 1.0 }
    }
    
    // 更新任务状态（用于拖拽）
    func updateTaskStatus(_ task: Task, newStatus: TaskStatus, context: ModelContext) {
        task.status = newStatus
        task.updatedAt = Date()
        if newStatus == .done && task.completedAt == nil {
            task.completedAt = Date()
        }
        updateTask(task, context: context)
    }
}

enum TaskFilter: String, CaseIterable {
    case todo = "待办"
    case inProgress = "进行中"
    case done = "已完成"
    case overdue = "已过期"
    case all = "全部" // 放在最后
}

enum TaskSort: String, CaseIterable {
    case priority = "优先级"
    case dueDate = "截止日期"
    case created = "创建时间"
    case name = "名称"
}

enum TaskViewMode: String, CaseIterable {
    case list = "列表"
    case kanban = "看板"
    case calendar = "日历"
}

