//
//  StatisticsViewModel.swift
//  FocusFlow
//
//  统计视图模型
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class StatisticsViewModel: ObservableObject {
    @Published var selectedPeriod: StatisticsPeriod = .today
    @Published var todayTotalMinutes: Int = 0
    @Published var weekTotalMinutes: Int = 0
    @Published var monthTotalMinutes: Int = 0
    @Published var totalSessions: Int = 0
    @Published var averageSessionMinutes: Int = 0
    @Published var longestSessionMinutes: Int = 0
    
    // 图表数据
    @Published var dailyTrendData: [(date: Date, minutes: Int)] = []
    @Published var tagDistributionData: [(tag: String, minutes: Int)] = []
    @Published var weeklyComparisonData: [(week: String, minutes: Int)] = []
    @Published var heatmapData: [Date: Int] = [:] // 年度热力图数据
    
    // 效率分析数据
    @Published var averageSessionDurationData: [(date: Date, minutes: Int)] = [] // 平均单次专注时长趋势
    @Published var longestSessionDate: Date? // 最长专注记录日期
    @Published var longestSessionMinutesInEfficiency: Int = 0 // 最长专注记录时长（效率分析专用）
    @Published var hourDistributionData: [(hour: Int, minutes: Int)] = [] // 24小时专注分布
    @Published var weekdayDistributionData: [(weekday: Int, minutes: Int)] = [] // 周内专注分布（0=周日, 1=周一...）
    
    private var modelContext: ModelContext?
    private var isCalculating = false // 防止重复计算
    private var lastSessionsHash: Int = 0 // 缓存 sessions 的哈希值
    private var taskCache: [UUID: Task] = [:] // 任务缓存，避免重复查询
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func updateStatistics(from sessions: [FocusSession]) {
        // 防止重复计算
        guard !isCalculating else { return }
        
        // 计算 sessions 的哈希值（基于数量和已完成数量）
        let completedCount = sessions.filter { $0.isCompleted }.count
        let sessionsHash = sessions.count * 1000 + completedCount
        if sessionsHash == lastSessionsHash {
            return // 数据没有变化，跳过计算
        }
        lastSessionsHash = sessionsHash
        
        isCalculating = true
        
        // 在主线程获取 tasks 和日期信息（避免在后台线程访问 ModelContext）
        let allTasks: [UUID: Task]
        if let context = modelContext {
            let taskDescriptor = FetchDescriptor<Task>()
            if let tasks = try? context.fetch(taskDescriptor) {
                allTasks = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
            } else {
                allTasks = [:]
            }
        } else {
            allTasks = [:]
        }
        
        // 在主线程计算日期基准值
        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        let weekStart = DateUtils.startOfWeek()
        let monthStart = DateUtils.startOfMonth()
        
        // 在后台线程进行计算
        _Concurrency.Task.detached { [weak self] in
            guard let self = self else { return }
            
            // 过滤完成的会话（在后台线程进行）
            let completedSessions = sessions.filter { $0.isCompleted }
            
            // 计算统计数据（在后台线程）
            // 今日统计
            let todaySessions = completedSessions.filter { session in
                calendar.isDate(session.startTime, inSameDayAs: todayStart)
            }
            let todayMinutes = todaySessions.reduce(0) { $0 + ($1.duration / 60) }
            
            // 本周统计
            let weekSessions = completedSessions.filter { $0.startTime >= weekStart }
            let weekMinutes = weekSessions.reduce(0) { $0 + ($1.duration / 60) }
            
            // 本月统计
            let monthSessions = completedSessions.filter { $0.startTime >= monthStart }
            let monthMinutes = monthSessions.reduce(0) { $0 + ($1.duration / 60) }
            
            // 总体统计
            let sessionsCount = completedSessions.count
            let avgMinutes: Int
            let longestMinutes: Int
            
            if sessionsCount > 0 {
                let totalMinutes = completedSessions.reduce(0) { $0 + ($1.duration / 60) }
                avgMinutes = totalMinutes / sessionsCount
                longestMinutes = completedSessions.map { $0.duration / 60 }.max() ?? 0
            } else {
                avgMinutes = 0
                longestMinutes = 0
            }
            
            // 计算图表数据（在后台线程）
            let chartData = self.calculateChartData(
                from: completedSessions,
                calendar: calendar,
                now: now,
                weekStart: weekStart,
                allTasks: allTasks
            )
            
            // 回到主线程更新 UI
            await MainActor.run {
                self.todayTotalMinutes = todayMinutes
                self.weekTotalMinutes = weekMinutes
                self.monthTotalMinutes = monthMinutes
                self.totalSessions = sessionsCount
                self.averageSessionMinutes = avgMinutes
                self.longestSessionMinutes = longestMinutes
                
                // 更新图表数据
                self.dailyTrendData = chartData.dailyTrend
                self.tagDistributionData = chartData.tagDistribution
                self.weeklyComparisonData = chartData.weeklyComparison
                self.heatmapData = chartData.heatmap
                self.averageSessionDurationData = chartData.averageSessionDuration
                self.longestSessionDate = chartData.longestSessionDate
                self.longestSessionMinutesInEfficiency = chartData.longestSessionMinutes
                self.hourDistributionData = chartData.hourDistribution
                self.weekdayDistributionData = chartData.weekdayDistribution
                
                self.isCalculating = false
            }
        }
    }
    
    // MARK: - 后台计算辅助结构
    private struct ChartDataResult {
        let dailyTrend: [(date: Date, minutes: Int)]
        let tagDistribution: [(tag: String, minutes: Int)]
        let weeklyComparison: [(week: String, minutes: Int)]
        let heatmap: [Date: Int]
        let averageSessionDuration: [(date: Date, minutes: Int)]
        let longestSessionDate: Date?
        let longestSessionMinutes: Int
        let hourDistribution: [(hour: Int, minutes: Int)]
        let weekdayDistribution: [(weekday: Int, minutes: Int)]
    }
    
    // MARK: - 图表数据计算（在后台线程）
    nonisolated private func calculateChartData(
        from sessions: [FocusSession],
        calendar: Calendar,
        now: Date,
        weekStart: Date,
        allTasks: [UUID: Task]
    ) -> ChartDataResult {
        
        // 每日趋势数据（最近30天）- 优化：使用字典分组而不是重复过滤
        var dailyData: [Date: Int] = [:]
        var sessionByDay: [Date: [FocusSession]] = [:]
        
        // 先按日期分组
        for session in sessions {
            let dayStart = calendar.startOfDay(for: session.startTime)
            if sessionByDay[dayStart] == nil {
                sessionByDay[dayStart] = []
            }
            sessionByDay[dayStart]?.append(session)
        }
        
        // 计算最近30天的数据
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                let dayStart = calendar.startOfDay(for: date)
                let daySessions = sessionByDay[dayStart] ?? []
                dailyData[dayStart] = daySessions.reduce(0) { $0 + ($1.duration / 60) }
            }
        }
        
        let dailyTrend = dailyData.sorted { $0.key > $1.key }.map { (date: $0.key, minutes: $0.value) }
        
        // 标签分布数据 - 优化：使用缓存的任务字典，避免数据库查询
        var tagData: [String: Int] = [:]
        for session in sessions {
            if let taskId = session.taskId, let task = allTasks[taskId], !task.tags.isEmpty {
                for tag in task.tags {
                    tagData[tag] = (tagData[tag] ?? 0) + (session.duration / 60)
                }
            } else {
                tagData["无标签"] = (tagData["无标签"] ?? 0) + (session.duration / 60)
            }
        }
        
        let tagDistribution = tagData.sorted { $0.value > $1.value }.map { (tag: $0.key, minutes: $0.value) }
        
        // 本周与上周对比
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart) ?? weekStart
        let lastWeekEnd = calendar.date(byAdding: .day, value: 6, to: lastWeekStart) ?? now
        
        let thisWeekSessions = sessions.filter { $0.startTime >= weekStart }
        let lastWeekSessions = sessions.filter { 
            $0.startTime >= lastWeekStart && $0.startTime <= lastWeekEnd
        }
        
        let thisWeekMinutes = thisWeekSessions.reduce(0) { $0 + ($1.duration / 60) }
        let lastWeekMinutes = lastWeekSessions.reduce(0) { $0 + ($1.duration / 60) }
        
        let weeklyComparison = [
            (week: "本周", minutes: thisWeekMinutes),
            (week: "上周", minutes: lastWeekMinutes)
        ]
        
        // 年度热力图数据（最近365天）- 优化：使用已分组的数据
        var heatmap: [Date: Int] = [:]
        for i in 0..<365 {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                let dayStart = calendar.startOfDay(for: date)
                let daySessions = sessionByDay[dayStart] ?? []
                heatmap[dayStart] = daySessions.reduce(0) { $0 + ($1.duration / 60) }
            }
        }
        
        // 效率分析数据
        let efficiencyData = calculateEfficiencyAnalysis(from: sessions, calendar: calendar)
        
        return ChartDataResult(
            dailyTrend: dailyTrend,
            tagDistribution: tagDistribution,
            weeklyComparison: weeklyComparison,
            heatmap: heatmap,
            averageSessionDuration: efficiencyData.averageSessionDuration,
            longestSessionDate: efficiencyData.longestSessionDate,
            longestSessionMinutes: efficiencyData.longestSessionMinutes,
            hourDistribution: efficiencyData.hourDistribution,
            weekdayDistribution: efficiencyData.weekdayDistribution
        )
    }
    
    // MARK: - 效率分析数据计算
    private struct EfficiencyDataResult {
        let averageSessionDuration: [(date: Date, minutes: Int)]
        let longestSessionDate: Date?
        let longestSessionMinutes: Int
        let hourDistribution: [(hour: Int, minutes: Int)]
        let weekdayDistribution: [(weekday: Int, minutes: Int)]
    }
    
    nonisolated private func calculateEfficiencyAnalysis(from sessions: [FocusSession], calendar: Calendar) -> EfficiencyDataResult {
        // 1. 平均单次专注时长趋势（最近30天）
        var dailyAverageData: [Date: [Int]] = [:]
        for session in sessions {
            let dayStart = calendar.startOfDay(for: session.startTime)
            let sessionMinutes = session.duration / 60
            if dailyAverageData[dayStart] == nil {
                dailyAverageData[dayStart] = []
            }
            dailyAverageData[dayStart]?.append(sessionMinutes)
        }
        
        let averageSessionDuration = dailyAverageData.map { (date, minutesList) in
            let average = minutesList.reduce(0, +) / minutesList.count
            return (date: date, minutes: average)
        }.sorted { $0.date > $1.date }.prefix(30).map { $0 }
        
        // 2. 最长专注记录
        let longestSession = sessions.max(by: { $0.duration < $1.duration })
        let longestSessionDate = longestSession?.startTime
        let longestSessionMinutes = (longestSession?.duration ?? 0) / 60
        
        // 3. 24小时专注分布（按开始时间的小时）
        var hourData: [Int: Int] = [:]
        for session in sessions {
            let hour = calendar.component(.hour, from: session.startTime)
            let sessionMinutes = session.duration / 60
            hourData[hour] = (hourData[hour] ?? 0) + sessionMinutes
        }
        
        let hourDistribution = (0..<24).map { hour in
            (hour: hour, minutes: hourData[hour] ?? 0)
        }
        
        // 4. 周内专注分布（按开始时间的星期）
        var weekdayData: [Int: Int] = [:]
        for session in sessions {
            let weekday = calendar.component(.weekday, from: session.startTime) - 1 // 转换为0-6（周日=0）
            let sessionMinutes = session.duration / 60
            weekdayData[weekday] = (weekdayData[weekday] ?? 0) + sessionMinutes
        }
        
        let weekdayDistribution = (0..<7).map { weekday in
            (weekday: weekday, minutes: weekdayData[weekday] ?? 0)
        }
        
        return EfficiencyDataResult(
            averageSessionDuration: averageSessionDuration,
            longestSessionDate: longestSessionDate,
            longestSessionMinutes: longestSessionMinutes,
            hourDistribution: hourDistribution,
            weekdayDistribution: weekdayDistribution
        )
    }
    
    var currentPeriodTotalMinutes: Int {
        switch selectedPeriod {
        case .today:
            return todayTotalMinutes
        case .week:
            return weekTotalMinutes
        case .month:
            return monthTotalMinutes
        }
    }
}

enum StatisticsPeriod: String, CaseIterable {
    case today = "今日"
    case week = "本周"
    case month = "本月"
}
