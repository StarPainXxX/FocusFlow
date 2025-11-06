//
//  FocusRepository.swift
//  FocusFlow
//
//  专注记录仓库
//

import Foundation
import SwiftData

@MainActor
class FocusRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// 保存专注记录
    func saveSession(_ session: FocusSession) {
        modelContext.insert(session)
        do {
            try modelContext.save()
            Logger.info("保存专注记录成功: \(session.id)", category: .data)
        } catch {
            Logger.error("保存专注记录失败: \(error.localizedDescription)", category: .data)
        }
    }
    
    /// 获取所有专注记录
    func getAllSessions(userId: String) -> [FocusSession] {
        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            Logger.error("获取专注记录失败: \(error.localizedDescription)", category: .data)
            return []
        }
    }
    
    /// 获取今日专注记录
    func getTodaySessions(userId: String) -> [FocusSession] {
        let startOfToday = DateUtils.startOfToday()
        let endOfToday = DateUtils.endOfToday()
        
        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { session in
                session.userId == userId &&
                session.startTime >= startOfToday &&
                session.startTime < endOfToday
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            Logger.error("获取今日专注记录失败: \(error.localizedDescription)", category: .data)
            return []
        }
    }
    
    /// 获取本周专注记录
    func getWeekSessions(userId: String) -> [FocusSession] {
        let startOfWeek = DateUtils.startOfWeek()
        
        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { session in
                session.userId == userId &&
                session.startTime >= startOfWeek
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            Logger.error("获取本周专注记录失败: \(error.localizedDescription)", category: .data)
            return []
        }
    }
    
    /// 删除专注记录
    func deleteSession(_ session: FocusSession) {
        modelContext.delete(session)
        do {
            try modelContext.save()
            Logger.info("删除专注记录成功: \(session.id)", category: .data)
        } catch {
            Logger.error("删除专注记录失败: \(error.localizedDescription)", category: .data)
        }
    }
    
    /// 计算今日总专注时长（分钟）
    func getTodayTotalDuration(userId: String) -> Int {
        let sessions = getTodaySessions(userId: userId)
        let totalSeconds = sessions.reduce(0) { $0 + $1.duration }
        return totalSeconds / 60
    }
}

