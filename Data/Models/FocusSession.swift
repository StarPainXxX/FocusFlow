//
//  FocusSession.swift
//  FocusFlow
//
//  专注会话记录模型
//

import Foundation
import SwiftData

@Model
final class FocusSession {
    var id: UUID
    var userId: String
    var startTime: Date
    var endTime: Date?
    var duration: Int // 实际专注时长（秒）
    var plannedDuration: Int // 计划时长（秒）
    var type: FocusType // "focus" / "pomodoro"
    var mode: FocusMode // "work" / "rest" / "longrest"
    var taskId: UUID?
    var taskName: String?
    var tags: [String]
    var notes: String?
    var pauseCount: Int
    var interruptionCount: Int
    var isCompleted: Bool
    var device: DeviceType
    var deviceModel: String?
    var syncStatus: SyncStatus
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        userId: String,
        startTime: Date = Date(),
        endTime: Date? = nil,
        duration: Int = 0,
        plannedDuration: Int,
        type: FocusType = .focus,
        mode: FocusMode = .work,
        taskId: UUID? = nil,
        taskName: String? = nil,
        tags: [String] = [],
        notes: String? = nil,
        pauseCount: Int = 0,
        interruptionCount: Int = 0,
        isCompleted: Bool = false,
        device: DeviceType = .ios,
        deviceModel: String? = nil,
        syncStatus: SyncStatus = .pending,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.plannedDuration = plannedDuration
        self.type = type
        self.mode = mode
        self.taskId = taskId
        self.taskName = taskName
        self.tags = tags
        self.notes = notes
        self.pauseCount = pauseCount
        self.interruptionCount = interruptionCount
        self.isCompleted = isCompleted
        self.device = device
        self.deviceModel = deviceModel
        self.syncStatus = syncStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - 枚举类型

enum FocusType: String, Codable {
    case focus = "focus"
    case pomodoro = "pomodoro"
}

enum FocusMode: String, Codable {
    case work = "work"
    case rest = "rest"
    case longrest = "longrest"
}

enum DeviceType: String, Codable {
    case ios = "ios"
    case macos = "macos"
    case ipados = "ipados"
}

enum SyncStatus: String, Codable {
    case synced = "synced"
    case pending = "pending"
    case failed = "failed"
}

