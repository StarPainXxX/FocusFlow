//
//  AppError.swift
//  FocusFlow
//
//  自定义错误类型
//

import Foundation

enum AppError: LocalizedError {
    case invalidDuration
    case timerNotRunning
    case timerAlreadyRunning
    case dataNotFound
    case syncFailed(String)
    case networkError(String)
    case storageError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidDuration:
            return "无效的专注时长"
        case .timerNotRunning:
            return "计时器未运行"
        case .timerAlreadyRunning:
            return "计时器已在运行中"
        case .dataNotFound:
            return "数据未找到"
        case .syncFailed(let message):
            return "同步失败: \(message)"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .storageError(let message):
            return "存储错误: \(message)"
        }
    }
}

