//
//  KanbanComponents.swift
//  FocusFlow
//
//  看板组件
//

import SwiftUI
import SwiftData

// MARK: - 看板列组件
struct KanbanColumn: View {
    let title: String
    let tasks: [Task]
    let status: TaskStatus
    let color: Color
    let viewModel: TasksViewModel
    let context: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 列标题
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                
                Spacer()
                
                Text("\(tasks.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            // 任务卡片
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(tasks) { task in
                        KanbanCard(
                            task: task,
                            onStatusChange: { newStatus in
                                viewModel.updateTaskStatus(task, newStatus: newStatus, context: context)
                            },
                            onEdit: {
                                viewModel.editingTask = task
                                viewModel.showTaskForm = true
                            },
                            onDelete: {
                                viewModel.deleteTask(task, context: context)
                            }
                        )
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
        .frame(width: 300)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - 看板卡片组件
struct KanbanCard: View {
    let task: Task
    let onStatusChange: (TaskStatus) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isDragging = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 任务标题和优先级
            HStack {
                Text(task.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
                
                // 优先级指示器
                Circle()
                    .fill(priorityColor)
                    .frame(width: 8, height: 8)
            }
            
            // 任务描述
            if let description = task.taskDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // 进度条
            if task.totalGoal > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: task.progressPercentage)
                        .tint(priorityColor)
                        .scaleEffect(x: 1, y: 1.5, anchor: .center)
                    
                    HStack {
                        Text("\(task.progress)/\(task.totalGoal) 分钟")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(task.progressPercentage * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 日期和标签
            HStack {
                // 显示任务日期（创建日期）
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(DateUtils.formatDate(task.createdAt, format: "MM-dd"))
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
                
                // 显示截止日期（如果有）
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(DateUtils.formatDate(dueDate, format: "MM-dd"))
                            .font(.caption2)
                    }
                    .foregroundColor(task.isOverdue ? .red : .secondary)
                }
                
                Spacer()
                
                // 标签（每个任务只能有一个标签）
                if let firstTag = task.tags.first {
                    Text(firstTag)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(getTagColor(for: firstTag))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            
            // 操作按钮
            HStack {
                // 状态切换按钮
                if task.status != .done {
                    Button(action: {
                        let nextStatus: TaskStatus = task.status == .todo ? .doing : .done
                        onStatusChange(nextStatus)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: task.status == .todo ? "play.fill" : "checkmark")
                            Text(task.status == .todo ? "开始" : "完成")
                        }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(priorityColor.opacity(0.2))
                        .foregroundColor(priorityColor)
                        .cornerRadius(6)
                    }
                }
                
                Spacer()
                
                // 编辑和删除按钮
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .scaleEffect(isDragging ? 0.95 : 1.0)
        .opacity(isDragging ? 0.8 : 1.0)
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .green
        }
    }
    
    // 获取标签颜色（用于标签框背景）
    @Query private var tags: [Tag]
    
    private func getTagColor(for tagName: String) -> Color {
        // 尝试从Tag模型中获取标签的颜色
        if let tag = tags.first(where: { $0.name == tagName }) {
            return Color(hex: tag.color)
        }
        // 如果没有找到，使用默认颜色
        return AppColors.primary
    }
}

#Preview {
    let container = try! ModelContainer(for: Task.self)
    return KanbanColumn(
        title: "待办",
        tasks: [
            Task(userId: "test", name: "测试任务", totalGoal: 60, priority: .high)
        ],
        status: .todo,
        color: .blue,
        viewModel: TasksViewModel(),
        context: container.mainContext
    )
}

