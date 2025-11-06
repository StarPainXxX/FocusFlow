//
//  DataExportView.swift
//  FocusFlow
//
//  数据导出视图
//

import SwiftUI
import SwiftData

struct DataExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [FocusSession]
    @Query private var tasks: [Task]
    @Query private var achievements: [Achievement]
    @Query private var users: [User]
    
    @State private var selectedFormat: ExportFormat = .json
    @State private var exportProgress: Double = 0
    @State private var isExporting = false
    @State private var exportSuccess = false
    @State private var exportedFileURL: URL?
    
    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("导出格式") {
                    Picker("格式", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("导出内容") {
                    HStack {
                        Text("专注记录")
                        Spacer()
                        Text("\(sessions.count) 条")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("任务")
                        Spacer()
                        Text("\(tasks.count) 条")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("成就")
                        Spacer()
                        Text("\(achievements.count) 条")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("用户数据")
                        Spacer()
                        Text(users.isEmpty ? "无" : "有")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: {
                        exportData()
                    }) {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            Text(isExporting ? "导出中..." : "导出数据")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isExporting || (sessions.isEmpty && tasks.isEmpty && achievements.isEmpty))
                }
                
                if exportSuccess, let fileURL = exportedFileURL {
                    Section("导出成功") {
                        Button(action: {
                            shareFile(fileURL)
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("分享文件")
                            }
                        }
                    }
                }
            }
            .navigationTitle("数据导出")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func exportData() {
        isExporting = true
        exportProgress = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            do {
                let fileURL: URL
                
                switch selectedFormat {
                case .json:
                    fileURL = try exportToJSON()
                case .csv:
                    fileURL = try exportToCSV()
                }
                
                exportedFileURL = fileURL
                exportSuccess = true
                exportProgress = 1.0
                
                Logger.info("数据导出成功: \(fileURL.lastPathComponent)", category: .data)
            } catch {
                Logger.error("数据导出失败: \(error.localizedDescription)", category: .data)
                exportSuccess = false
            }
            
            isExporting = false
        }
    }
    
    private func exportToJSON() throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "FocusFlow_Export_\(DateUtils.formatDate(Date(), format: "yyyyMMdd_HHmmss")).json"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        // 构建导出数据
        let exportData: [String: Any] = [
            "exportDate": DateUtils.formatDate(Date(), format: "yyyy-MM-dd HH:mm:ss"),
            "sessions": sessions.map { session in
                [
                    "id": session.id.uuidString,
                    "startTime": DateUtils.formatDate(session.startTime, format: "yyyy-MM-dd HH:mm:ss"),
                    "endTime": session.endTime != nil ? DateUtils.formatDate(session.endTime!, format: "yyyy-MM-dd HH:mm:ss") : nil,
                    "duration": session.duration,
                    "plannedDuration": session.plannedDuration,
                    "type": session.type.rawValue,
                    "mode": session.mode.rawValue,
                    "taskId": session.taskId?.uuidString,
                    "taskName": session.taskName,
                    "tags": session.tags,
                    "notes": session.notes,
                    "isCompleted": session.isCompleted
                ]
            },
            "tasks": tasks.map { task in
                [
                    "id": task.id.uuidString,
                    "name": task.name,
                    "description": task.taskDescription,
                    "totalGoal": task.totalGoal,
                    "progress": task.progress,
                    "priority": task.priority.rawValue,
                    "status": task.status.rawValue,
                    "dueDate": task.dueDate != nil ? DateUtils.formatDate(task.dueDate!, format: "yyyy-MM-dd") : nil,
                    "tags": task.tags,
                    "createdAt": DateUtils.formatDate(task.createdAt, format: "yyyy-MM-dd HH:mm:ss"),
                    "completedAt": task.completedAt != nil ? DateUtils.formatDate(task.completedAt!, format: "yyyy-MM-dd HH:mm:ss") : nil
                ]
            },
            "achievements": achievements.map { achievement in
                [
                    "id": achievement.id.uuidString,
                    "name": achievement.name,
                    "description": achievement.achievementDescription,
                    "type": achievement.achievementType.rawValue,
                    "isUnlocked": achievement.isUnlocked,
                    "unlockedAt": achievement.unlockedAt != nil ? DateUtils.formatDate(achievement.unlockedAt!, format: "yyyy-MM-dd HH:mm:ss") : nil
                ]
            },
            "user": users.first.map { user in
                [
                    "level": user.level,
                    "exp": user.exp,
                    "totalFocusTime": user.totalFocusTime,
                    "consecutiveDays": user.consecutiveDays,
                    "bestStreak": user.bestStreak,
                    "totalPomodoros": user.totalPomodoros
                ]
            } ?? [:]
        ]
        
        // 转换为JSON
        let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        try jsonData.write(to: fileURL)
        
        return fileURL
    }
    
    private func exportToCSV() throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "FocusFlow_Export_\(DateUtils.formatDate(Date(), format: "yyyyMMdd_HHmmss")).csv"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        var csvContent = "导出日期,\(DateUtils.formatDate(Date(), format: "yyyy-MM-dd HH:mm:ss"))\n\n"
        
        // 专注记录
        csvContent += "=== 专注记录 ===\n"
        csvContent += "ID,开始时间,结束时间,时长(秒),计划时长(秒),类型,模式,任务名称,标签,是否完成\n"
        for session in sessions {
            let tags = session.tags.joined(separator: ";")
            let endTime = session.endTime != nil ? DateUtils.formatDate(session.endTime!, format: "yyyy-MM-dd HH:mm:ss") : ""
            csvContent += "\(session.id.uuidString),\(DateUtils.formatDate(session.startTime, format: "yyyy-MM-dd HH:mm:ss")),\(endTime),\(session.duration),\(session.plannedDuration),\(session.type.rawValue),\(session.mode.rawValue),\(session.taskName ?? ""),\(tags),\(session.isCompleted)\n"
        }
        
        csvContent += "\n=== 任务 ===\n"
        csvContent += "ID,名称,描述,目标时长(分钟),进度(分钟),优先级,状态,截止日期,标签,创建时间,完成时间\n"
        for task in tasks {
            let tags = task.tags.joined(separator: ";")
            let dueDate = task.dueDate != nil ? DateUtils.formatDate(task.dueDate!, format: "yyyy-MM-dd") : ""
            let completedAt = task.completedAt != nil ? DateUtils.formatDate(task.completedAt!, format: "yyyy-MM-dd HH:mm:ss") : ""
            csvContent += "\(task.id.uuidString),\(task.name),\(task.taskDescription ?? ""),\(task.totalGoal),\(task.progress),\(task.priority.rawValue),\(task.status.rawValue),\(dueDate),\(tags),\(DateUtils.formatDate(task.createdAt, format: "yyyy-MM-dd HH:mm:ss")),\(completedAt)\n"
        }
        
        csvContent += "\n=== 成就 ===\n"
        csvContent += "ID,名称,描述,类型,是否解锁,解锁时间\n"
        for achievement in achievements {
            let unlockedAt = achievement.unlockedAt != nil ? DateUtils.formatDate(achievement.unlockedAt!, format: "yyyy-MM-dd HH:mm:ss") : ""
            csvContent += "\(achievement.id.uuidString),\(achievement.name),\(achievement.achievementDescription),\(achievement.achievementType.rawValue),\(achievement.isUnlocked),\(unlockedAt)\n"
        }
        
        csvContent += "\n=== 用户统计 ===\n"
        if let user = users.first {
            csvContent += "等级,经验值,总专注时长(分钟),连续天数,最长连续天数,总番茄数\n"
            csvContent += "\(user.level),\(user.exp),\(user.totalFocusTime),\(user.consecutiveDays),\(user.bestStreak),\(user.totalPomodoros)\n"
        }
        
        // 写入文件
        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
    
    private func shareFile(_ url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    DataExportView()
        .modelContainer(for: [FocusSession.self, Task.self, Achievement.self, User.self])
}

