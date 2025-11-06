//
//  TaskDetailView.swift
//  FocusFlow
//
//  任务详情视图
//

import SwiftUI
import SwiftData

struct TaskDetailView: View {
    let task: Task
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var focusViewModel: FocusViewModel
    @Query private var sessions: [FocusSession]
    @State private var showEditForm = false
    
    private var relatedSessions: [FocusSession] {
        sessions.filter { $0.taskId == task.id && $0.isCompleted }
    }
    
    private var totalFocusMinutes: Int {
        relatedSessions.reduce(0) { $0 + ($1.duration / 60) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 任务基本信息
                    taskInfoSection
                    
                    // 进度信息
                    progressSection
                    
                    // 关联的专注记录
                    relatedSessionsSection
                }
                .padding()
            }
            .navigationTitle(task.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 15) {
                        // 开始专注按钮
                        Button(action: {
                            focusViewModel.selectedTask = task
                            // 切换到专注页面
                            NotificationCenter.default.post(name: NSNotification.Name("SwitchToFocusTab"), object: nil)
                        }) {
                            Image(systemName: "timer")
                                .foregroundColor(AppColors.primary)
                        }
                        
                        // 编辑按钮
                        Button("编辑") {
                            showEditForm = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditForm) {
                TaskFormView(task: task, viewModel: TasksViewModel())
            }
        }
    }
    
    // MARK: - 任务信息
    private var taskInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            if let description = task.taskDescription, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("优先级", systemImage: "exclamationmark.circle")
                Spacer()
                Text(task.priority.displayName)
                    .fontWeight(.bold)
                    .foregroundColor(priorityColor)
            }
            
            HStack {
                Label("状态", systemImage: "checkmark.circle")
                Spacer()
                Text(statusText)
                    .fontWeight(.bold)
                    .foregroundColor(statusColor)
            }
            
            if let dueDate = task.dueDate {
                HStack {
                    Label("截止日期", systemImage: "calendar")
                    Spacer()
                    Text(DateUtils.formatDate(dueDate, format: "yyyy-MM-dd"))
                        .foregroundColor(task.isOverdue ? .red : .secondary)
                }
            }
            
            if !task.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("标签")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            // 每个任务只能有一个标签，所以只显示第一个
                            if let firstTag = task.tags.first {
                                Text(firstTag)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 进度信息
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("进度")
                .font(.headline)
            
            // 进度条
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(task.progress) / \(task.totalGoal) 分钟")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(Int(task.progressPercentage * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primary)
                }
                
                ProgressView(value: task.progressPercentage)
                    .tint(taskColor(task.colorTag))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            
            // 统计信息
            HStack(spacing: 30) {
                VStack {
                    Text("\(totalFocusMinutes)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("专注时长")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(relatedSessions.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("专注次数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if relatedSessions.count > 0 {
                    VStack {
                        Text("\(totalFocusMinutes / relatedSessions.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("平均时长")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 关联的专注记录
    private var relatedSessionsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("专注记录")
                .font(.headline)
            
            if relatedSessions.isEmpty {
                VStack {
                    Text("暂无专注记录")
                        .foregroundColor(.secondary)
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                ForEach(relatedSessions.prefix(10)) { session in
                    SessionRow(session: session)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
    
    private var statusText: String {
        switch task.status {
        case .todo:
            return "待办"
        case .doing:
            return "进行中"
        case .done:
            return "已完成"
        }
    }
    
    private var statusColor: Color {
        switch task.status {
        case .todo:
            return .gray
        case .doing:
            return .orange
        case .done:
            return .green
        }
    }
    
    private func taskColor(_ hex: String) -> Color {
        let trimmed = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard trimmed.count == 6 || trimmed.count == 3 || trimmed.count == 8 else {
            return .blue
        }
        return Color(hex: hex)
    }
}

// MARK: - 专注记录行
struct SessionRow: View {
    let session: FocusSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(DateUtils.formatDate(session.startTime, format: "MM-dd HH:mm"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !session.tags.isEmpty {
                    HStack(spacing: 5) {
                        ForEach(session.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray5))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            Spacer()
            
            Text("\(session.duration / 60) 分钟")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(AppColors.primary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    TaskDetailView(task: Task(userId: "test", name: "测试任务", totalGoal: 120))
        .modelContainer(for: [Task.self, FocusSession.self])
}

