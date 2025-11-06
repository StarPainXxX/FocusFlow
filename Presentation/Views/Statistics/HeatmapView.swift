//
//  HeatmapView.swift
//  FocusFlow
//
//  年度热力图视图
//

import SwiftUI
import SwiftData

struct HeatmapView: View {
    let data: [Date: Int]
    @State private var selectedDate: Date?
    @State private var selectedMinutes: Int = 0
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    private let calendar = Calendar.current
    private let weeksInYear = 27 // 27列（27周）
    private let daysInWeek = 7
    private let rows = 14 // 14行（2周）
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // 年份切换按钮
            yearSelector
            
            if data.isEmpty {
                VStack {
                    Text("暂无数据")
                        .foregroundColor(.secondary)
                        .padding()
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    // 热力图网格（包含月份标签和格子）
                    heatmapGrid
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 图例
                legend
                    .padding(.horizontal)
            }
            
            // 选中日期信息
            if let date = selectedDate {
                selectedDateInfo(date: date, minutes: selectedMinutes)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - 年份选择器
    private var yearSelector: some View {
        HStack {
            Button(action: {
                selectedYear -= 1
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text("\(selectedYear)年")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: {
                selectedYear += 1
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - 热力图网格
    private var heatmapGrid: some View {
        VStack(alignment: .leading, spacing: 2) {
            // 月份标签行（横排显示在顶部，只标注1、4、7、10月）
            monthLabelsRow
            
            // 热力图格子（横排：每列是一周，每行是星期几）
            // 使用同一个 ScrollView 确保月份标签和网格同步滚动
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 2) {
                    // 月份标签行（与网格内容对齐）
                    monthLabelsContent
                    
                    // 热力图格子
                    HStack(alignment: .top, spacing: 2) {
                        // 按周分组日期（27列，每列是一周）
                        ForEach(0..<weeksInYear, id: \.self) { weekIndex in
                            VStack(spacing: 2) {
                                // 14行，每行是星期几（循环：日、一、二、三、四、五、六、日、一、二、三、四、五、六）
                                ForEach(0..<rows, id: \.self) { rowIndex in
                                    let dayOfWeek = rowIndex % daysInWeek
                                    // 计算日期
                                    if let date = dateForWeek(weekIndex, dayOfWeek: dayOfWeek) {
                                        HeatmapCell(
                                            date: date,
                                            minutes: data[date] ?? 0,
                                            isSelected: selectedDate == date
                                        ) {
                                            selectedDate = date
                                            selectedMinutes = data[date] ?? 0
                                        }
                                    } else {
                                        // 空单元格
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.clear)
                                            .frame(width: 12, height: 12)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 月份标签行（横排显示在顶部，只标注1、4、7、10月）
    private var monthLabelsRow: some View {
        // 占位空间，保持与月份标签内容相同的高度
        HStack(spacing: 0) {
            ForEach(0..<weeksInYear, id: \.self) { week in
                // 获取这一周的第一天（周日）
                if let weekStartDate = dateForWeek(week, dayOfWeek: 0) {
                    let month = calendar.component(.month, from: weekStartDate)
                    let dayOfMonth = calendar.component(.day, from: weekStartDate)
                    
                    // 只标注1、4、7、10月，且是月初（1-7号）
                    if (month == 1 || month == 4 || month == 7 || month == 10) && dayOfMonth <= 7 {
                        Text("\(month)月")
                            .font(.caption2)
                            .foregroundColor(.clear) // 透明，仅用于占位
                            .frame(width: CGFloat(14 * daysInWeek), alignment: .leading)
                    } else {
                        Spacer()
                            .frame(width: 14)
                    }
                } else {
                    Spacer()
                        .frame(width: 14)
                }
            }
        }
        .frame(height: 14)
        .padding(.bottom, 4)
    }
    
    // MARK: - 月份标签内容（在 ScrollView 内，与网格同步滚动）
    private var monthLabelsContent: some View {
        HStack(spacing: 0) {
            ForEach(0..<weeksInYear, id: \.self) { week in
                // 获取这一周的第一天（周日）
                if let weekStartDate = dateForWeek(week, dayOfWeek: 0) {
                    let month = calendar.component(.month, from: weekStartDate)
                    let dayOfMonth = calendar.component(.day, from: weekStartDate)
                    
                    // 只标注1、4、7、10月，且是月初（1-7号）
                    if (month == 1 || month == 4 || month == 7 || month == 10) && dayOfMonth <= 7 {
                        Text("\(month)月")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: CGFloat(14 * daysInWeek), alignment: .leading)
                    } else {
                        Spacer()
                            .frame(width: 14)
                    }
                } else {
                    Spacer()
                        .frame(width: 14)
                }
            }
        }
        .frame(height: 14)
        .padding(.bottom, 4)
    }
    
    // MARK: - 图例
    private var legend: some View {
        HStack {
            Text("少")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            HStack(spacing: 2) {
                ForEach(Array(0..<5), id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatmapColor(for: level))
                        .frame(width: 10, height: 10)
                }
            }
            
            Text("多")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - 选中日期信息
    private func selectedDateInfo(date: Date, minutes: Int) -> some View {
        HStack {
            Text(DateUtils.formatDate(date, format: "yyyy-MM-dd"))
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
            Text("\(minutes) 分钟")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(AppColors.primary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - 计算属性
    /// 获取选定年份的起始日期（1月1日所在周的第一天，周日）
    private var yearStartDate: Date? {
        var components = DateComponents()
        components.year = selectedYear
        components.month = 1
        components.day = 1
        guard let yearStart = calendar.date(from: components) else {
            return nil
        }
        
        // 获取该年1月1日所在周的第一天（周日）
        let weekday = calendar.component(.weekday, from: yearStart)
        let daysFromSunday = (weekday + 6) % 7 // 转换为周日到周六（0-6）
        return calendar.date(byAdding: .day, value: -daysFromSunday, to: yearStart)
    }
    
    /// 根据周索引和星期几获取日期
    private func dateForWeek(_ weekIndex: Int, dayOfWeek: Int) -> Date? {
        guard let startDate = yearStartDate else {
            return nil
        }
        
        // 计算总天数偏移：第几周的第几天
        let dayOffset = weekIndex * daysInWeek + dayOfWeek
        
        // 计算日期
        guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else {
            return nil
        }
        
        // 只返回选定年份的日期（允许跨年的一些日期用于对齐）
        let dayStart = calendar.startOfDay(for: date)
        return dayStart
    }
    
    private func heatmapColor(for level: Int) -> Color {
        let colors: [Color] = [
            Color(.systemGray5),
            AppColors.primary.opacity(0.3),
            AppColors.primary.opacity(0.5),
            AppColors.primary.opacity(0.7),
            AppColors.primary
        ]
        return colors[min(level, colors.count - 1)]
    }
}

// MARK: - 热力图格子
struct HeatmapCell: View {
    let date: Date
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(heatmapColor)
            .frame(width: 12, height: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2)
            )
            .onTapGesture {
                action()
            }
    }
    
    private var heatmapColor: Color {
        if minutes == 0 {
            return Color(.systemGray5)
        } else if minutes < 30 {
            return AppColors.primary.opacity(0.3)
        } else if minutes < 60 {
            return AppColors.primary.opacity(0.5)
        } else if minutes < 120 {
            return AppColors.primary.opacity(0.7)
        } else {
            return AppColors.primary
        }
    }
}

#Preview {
    HeatmapView(data: [:])
}
