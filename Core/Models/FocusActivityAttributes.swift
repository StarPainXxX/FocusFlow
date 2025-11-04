//
//  FocusActivityAttributes.swift
//  FocusFlow
//
//  Live Activity 属性定义
//

import Foundation
import ActivityKit

struct FocusActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // 动态状态
        var remainingSeconds: Int
        var totalSeconds: Int
        var taskName: String?
        var taskIcon: String? // 任务图标（SF Symbol 名称）
        var taskColor: String? // 任务颜色（HEX 格式）
        var isPaused: Bool
    }
    
    // 静态属性
    var sessionId: String
    var startTime: Date
}

