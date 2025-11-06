//
//  TaskPickerView.swift
//  FocusFlow
//
//  任务选择器视图
//

import SwiftUI
import SwiftData

struct TaskPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\Task.createdAt, order: .reverse)]) private var tasks: [Task]
    @Binding var selectedTask: Task?
    
    var body: some View {
        NavigationStack {
            List {
                // 任务列表（必须选择任务，不能选择"无任务"）
                // "专注"任务永远在最上面
                // 注意：任务列表（TasksView）中会过滤掉"专注"任务，只显示自定义任务
                let filteredTasks = tasks.filter { $0.status != .done && !$0.isArchived }
                let focusTask = filteredTasks.first { $0.name == "专注" }
                let otherTasks = filteredTasks.filter { $0.name != "专注" }
                
                // 先显示"专注"任务
                if let focusTask = focusTask {
                    TaskPickerRow(
                        task: focusTask,
                        isSelected: selectedTask?.id == focusTask.id
                    ) {
                        selectedTask = focusTask
                        dismiss()
                    }
                }
                
                // 然后显示其他任务
                ForEach(otherTasks) { task in
                    TaskPickerRow(
                        task: task,
                        isSelected: selectedTask?.id == task.id
                    ) {
                        selectedTask = task
                        dismiss()
                    }
                }
            }
            .navigationTitle("选择任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 任务选择行
struct TaskPickerRow: View {
    let task: Task
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Query private var tags: [Tag]
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // 任务标签颜色指示器（使用第一个标签的颜色）
                Circle()
                    .fill(getTaskTagColor(task))
                    .frame(width: 12, height: 12)
                
                // 任务信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    // 进度信息（默认"专注"任务不显示时间进度）
                    if task.name != "专注" && task.totalGoal > 0 {
                        HStack(spacing: 8) {
                            Text("\(task.progress) / \(task.totalGoal) 分钟")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // 进度条
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .frame(height: 4)
                                    
                                    Rectangle()
                                        .fill(taskColor(task.colorTag))
                                        .frame(width: geometry.size.width * task.progressPercentage, height: 4)
                                }
                            }
                            .frame(height: 4)
                        }
                    }
                }
                
                Spacer()
                
                // 选中标记
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(AppColors.primary)
                        .fontWeight(.bold)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func taskColor(_ colorHex: String) -> Color {
        Color(hex: colorHex)
    }
    
    // 获取任务标签颜色（使用第一个标签的颜色）
    private func getTaskTagColor(_ task: Task) -> Color {
        // 如果任务有标签，尝试从Tag模型中获取第一个标签的颜色
        if let firstTagName = task.tags.first {
            if let tag = tags.first(where: { $0.name == firstTagName }) {
                return Color(hex: tag.color)
            }
        }
        // 如果没有标签或找不到Tag，使用任务的colorTag
        return taskColor(task.colorTag)
    }
}

#Preview {
    TaskPickerView(selectedTask: .constant(nil))
        .modelContainer(for: [Task.self])
}

