//
//  CalendarDayCell.swift
//  FocusFlow
//
//  日历日期单元格
//

import SwiftUI
import SwiftData

struct CalendarDayCell: View {
    let date: Date?
    let isCurrentMonth: Bool
    let isToday: Bool
    let tasks: [Task]
    let onDateTap: (Date) -> Void
    
    var body: some View {
        Button(action: {
            if let date = date {
                onDateTap(date)
            }
        }) {
            VStack(spacing: 4) {
                // 日期数字
                if let date = date {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: isToday ? 16 : 14, weight: isToday ? .bold : .regular))
                        .foregroundColor(isCurrentMonth ? (isToday ? .white : .primary) : .secondary)
                        .frame(width: 30, height: 30)
                        .background(isToday ? AppColors.primary : Color.clear)
                        .cornerRadius(15)
                    
                    // 任务指示点
                    if !tasks.isEmpty {
                        HStack(spacing: 2) {
                            ForEach(Array(tasks.prefix(3).enumerated()), id: \.offset) { index, task in
                                Circle()
                                    .fill(taskPriorityColor(task.priority))
                                    .frame(width: 4, height: 4)
                            }
                            
                            if tasks.count > 3 {
                                Text("+\(tasks.count - 3)")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(isCurrentMonth ? Color.clear : Color(.systemGray5).opacity(0.3))
        }
        .buttonStyle(.plain)
    }
    
    private func taskPriorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .green
        }
    }
}

#Preview {
    CalendarDayCell(
        date: Date(),
        isCurrentMonth: true,
        isToday: true,
        tasks: [
            Task(userId: "test", name: "测试任务", totalGoal: 60, priority: .high)
        ],
        onDateTap: { _ in }
    )
}

