//
//  Logger.swift
//  FocusFlow
//
//  日志工具
//

import Foundation
import os.log

struct Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.focusflow"
    
    enum Category: String {
        case app = "App"
        case timer = "Timer"
        case data = "Data"
        case sync = "Sync"
        case ui = "UI"
    }
    
    static func log(_ message: String, category: Category = .app, type: OSLogType = .default) {
        let logger = OSLog(subsystem: subsystem, category: category.rawValue)
        os_log("%{public}@", log: logger, type: type, message)
    }
    
    static func debug(_ message: String, category: Category = .app) {
        log(message, category: category, type: .debug)
    }
    
    static func error(_ message: String, category: Category = .app) {
        log(message, category: category, type: .error)
    }
    
    static func info(_ message: String, category: Category = .app) {
        log(message, category: category, type: .info)
    }
}

