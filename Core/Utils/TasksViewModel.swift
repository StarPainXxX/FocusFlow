//
//  TasksViewModel.swift
//  FocusFlow
//
//  任务视图模型
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
class TasksViewModel: ObservableObject {
    @Published var selectedFilter: TaskFilter = .all
    @Published var selectedSort: TaskSort = .priority
    @Published var showTaskForm = false
    @Published var editingTask: Task?
    
    var filteredTasks: [Task] {
        var tasks = allTasks
        
        // 应用筛选
        switch selectedFilter {
        case .all:
            break
        case .todo:
            tasks = tasks.filter { $0.status == .todo }
        case .inProgress:
            tasks = tasks.filter { $0.status == .inProgress }
        case .done:
            tasks = tasks.filter { $0.status == .done }
        case .overdue:
            tasks = tasks.filter { $0.isOverdue }
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
    
    private var allTasks: [Task] = []
    
    func updateTasks(_ tasks: [Task]) {
        allTasks = tasks
    }
    
    func createTask(
        name: String,
        taskDescription: String?,
        totalGoal: Int,
        priority: TaskPriority,
        dueDate: Date?,
        context: ModelContext
    ) {
        let task = Task(
            userId: "default-user",
            name: name,
            taskDescription: taskDescription,
            totalGoal: totalGoal,
            priority: priority,
            dueDate: dueDate
        )
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
}

enum TaskFilter: String, CaseIterable {
    case all = "全部"
    case todo = "待办"
    case inProgress = "进行中"
    case done = "已完成"
    case overdue = "已过期"
}

enum TaskSort: String, CaseIterable {
    case priority = "优先级"
    case dueDate = "截止日期"
    case created = "创建时间"
    case name = "名称"
}

