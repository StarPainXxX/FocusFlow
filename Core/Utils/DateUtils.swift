//
//  DateUtils.swift
//  FocusFlow
//
//  日期工具类
//

import Foundation

struct DateUtils {
    /// 格式化日期为字符串
    static func formatDate(_ date: Date, format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    /// 格式化时长为字符串（分钟）
    static func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return "\(hours)小时\(mins)分钟"
        } else {
            return "\(mins)分钟"
        }
    }
    
    /// 格式化时长为字符串（秒）
    static func formatDurationFromSeconds(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    /// 获取今天的开始时间
    static func startOfToday() -> Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: Date())
    }
    
    /// 获取今天的结束时间
    static func endOfToday() -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: 1, to: today) ?? Date()
    }
    
    /// 判断是否为同一天
    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, inSameDayAs: date2)
    }
    
    /// 获取本周的开始时间
    nonisolated static func startOfWeek() -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = (weekday + 5) % 7 // 转换为周一开始
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: today) ?? today
    }
    
    /// 获取本月的开始时间
    nonisolated static func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: components) ?? Date()
    }
    
    /// 获取星期名称（0=周日, 1=周一, ..., 6=周六）
    static func weekdayName(_ weekday: Int) -> String {
        let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return weekdays[min(max(weekday, 0), 6)]
    }
}

