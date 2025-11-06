//
//  StatisticsView.swift
//  FocusFlow
//
//  统计视图
//

import SwiftUI
import SwiftData
import Charts
import Combine

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusSession.startTime, order: .reverse) private var sessions: [FocusSession]
    @Query private var users: [User]
    @StateObject private var viewModel = StatisticsViewModel()
    @State private var lastSessionCount: Int = 0
    @State private var lastCompletedCount: Int = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 时间段选择
                    periodSelector
                    
                    // 总览卡片
                    overviewCards
                    
                    // 详细统计
                    detailStatistics
                    
                    // 专注趋势图
                    trendChart
                    
                    // 标签分布图（圆形统计）
                    tagDistributionCircleChart
                    
                    // 周对比图
                    weeklyComparisonChart
                    
                    // 专注效率分析
                    efficiencyAnalysisSection
                }
                .padding()
            }
            .navigationTitle("统计")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.setModelContext(modelContext)
                // 延迟加载统计数据，避免阻塞UI渲染
                DispatchQueue.main.async {
                    viewModel.updateStatistics(from: sessions)
                }
            }
            .onChange(of: sessions.count) { oldCount, newCount in
                // 当sessions数量变化时，更新统计
                if newCount != oldCount {
                    viewModel.updateStatistics(from: sessions)
                }
            }
            .onChange(of: sessions) { oldSessions, newSessions in
                // 检查已完成数量是否变化
                let oldCompleted = oldSessions.filter { $0.isCompleted }.count
                let newCompleted = newSessions.filter { $0.isCompleted }.count
                if newCompleted != oldCompleted {
                    viewModel.updateStatistics(from: newSessions)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FocusSessionCompleted"))) { _ in
                // 当专注完成时，延迟刷新统计以确保数据已保存
                modelContext.processPendingChanges()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let completedCount = sessions.filter { $0.isCompleted }.count
                    if completedCount != lastCompletedCount {
                        lastCompletedCount = completedCount
                        viewModel.updateStatistics(from: sessions)
                    }
                }
            }
        }
    }
    
    // MARK: - 时间段选择器
    private var periodSelector: some View {
        Picker("时间段", selection: $viewModel.selectedPeriod) {
            ForEach(StatisticsPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - 总览卡片
    private var overviewCards: some View {
        VStack(spacing: 15) {
            // 总时长卡片
            StatCard(
                title: "总时长",
                value: "\(viewModel.currentPeriodTotalMinutes)",
                unit: "分钟",
                icon: "clock.fill",
                color: .blue
            )
            
            // 会话数卡片
            StatCard(
                title: "会话数",
                value: "\(viewModel.totalSessions)",
                unit: "次",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            // 平均时长卡片
            StatCard(
                title: "平均时长",
                value: "\(viewModel.averageSessionMinutes)",
                unit: "分钟",
                icon: "chart.bar.fill",
                color: .orange
            )
            
            // 最长时长卡片
            StatCard(
                title: "最长时长",
                value: "\(viewModel.longestSessionMinutes)",
                unit: "分钟",
                icon: "star.fill",
                color: .purple
            )
        }
    }
    
    // MARK: - 详细统计
    private var detailStatistics: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("详细统计")
                .font(.headline)
                .padding(.horizontal)
            
            // 用户信息
            if let user = users.first {
                VStack(spacing: 10) {
                    HStack {
                        Text("等级")
                        Spacer()
                        Text("Lv.\(user.level)")
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("经验值")
                        Spacer()
                        Text("\(user.exp)")
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("总专注时长")
                        Spacer()
                        Text("\(user.totalFocusTime) 分钟")
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("连续天数")
                        Spacer()
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(user.consecutiveDays) 天")
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - 专注趋势图
    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("专注趋势（最近30天）")
                .font(.headline)
                .padding(.horizontal)
            
            if viewModel.dailyTrendData.isEmpty {
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
                Chart {
                    ForEach(Array(viewModel.dailyTrendData.enumerated()), id: \.offset) { index, data in
                        LineMark(
                            x: .value("日期", index),
                            y: .value("分钟", data.minutes)
                        )
                        .foregroundStyle(AppColors.primary)
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("日期", index),
                            y: .value("分钟", data.minutes)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.primary.opacity(0.3), AppColors.primary.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 200)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - 标签分布圆形统计图
    private var tagDistributionCircleChart: some View {
        VStack(alignment: .leading, spacing: 15) {
            // 标题放在最上层，确保不被遮挡
            Text("标签分布")
                .font(.headline)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if viewModel.tagDistributionData.isEmpty {
                VStack {
                    Text("暂无数据")
                        .foregroundColor(.secondary)
                        .padding()
                }
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                // 一个圆形统计图，中间显示总时长，按标签时长和颜色占据圆弧比例
                TagDistributionCircleView(
                    tagData: viewModel.tagDistributionData,
                    modelContext: modelContext,
                    onTagSelected: { tag, minutes in
                        // 可以在这里显示选中的标签信息
                    }
                )
                .padding(.horizontal)
            }
        }
        .padding(.top, 5) // 增加顶部间距，避免标题被遮挡
    }
    
    // MARK: - 标签分布图（柱状图）
    private var tagDistributionChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("标签分布")
                .font(.headline)
                .padding(.horizontal)
            
            if viewModel.tagDistributionData.isEmpty {
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
                Chart {
                    ForEach(Array(viewModel.tagDistributionData.prefix(10).enumerated()), id: \.offset) { index, data in
                        BarMark(
                            x: .value("标签", data.tag),
                            y: .value("分钟", data.minutes)
                        )
                        .foregroundStyle(
                            Color(hex: AppColors.tagColors[index % AppColors.tagColors.count])
                        )
                    }
                }
                .frame(height: 200)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - 周对比图
    private var weeklyComparisonChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("周对比")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(viewModel.weeklyComparisonData, id: \.week) { data in
                    BarMark(
                        x: .value("周", data.week),
                        y: .value("分钟", data.minutes)
                    )
                    .foregroundStyle(
                        data.week == "本周" ? AppColors.primary : Color.gray
                    )
                }
            }
            .frame(height: 150)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    // MARK: - 专注效率分析
    private var efficiencyAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("专注效率分析")
                .font(.headline)
                .padding(.horizontal)
            
            // 最长专注记录
            longestSessionCard
            
            // 24小时专注分布
            hourDistributionChart
            
            // 周内专注分布
            weekdayDistributionChart
        }
    }
    
    // MARK: - 最长专注记录卡片
    private var longestSessionCard: some View {
        Group {
            if viewModel.longestSessionMinutesInEfficiency > 0 {
                HStack {
                    Text("最长单次专注:")
                    Spacer()
                    Text("\(viewModel.longestSessionMinutesInEfficiency) 分钟")
                        .fontWeight(.bold)
                    if let date = viewModel.longestSessionDate {
                        Text("(\(DateUtils.formatDate(date, format: "MM-dd")))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - 24小时专注分布图
    private var hourDistributionChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("24小时专注时段分布")
                .font(.subheadline)
            if viewModel.hourDistributionData.isEmpty {
                Text("暂无数据")
                    .foregroundColor(.secondary)
            } else {
                Chart {
                    ForEach(viewModel.hourDistributionData, id: \.hour) { data in
                        BarMark(
                            x: .value("小时", "\(data.hour)时"),
                            y: .value("分钟", data.minutes)
                        )
                        .foregroundStyle(AppColors.secondary)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 3)) { value in
                        AxisValueLabel()
                    }
                }
                .frame(height: 150)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - 周内专注分布图
    private var weekdayDistributionChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("周内专注分布")
                .font(.subheadline)
            if viewModel.weekdayDistributionData.isEmpty {
                Text("暂无数据")
                    .foregroundColor(.secondary)
            } else {
                weekdayChart
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - 周内分布图表
    private var weekdayChart: some View {
        Chart {
            ForEach(viewModel.weekdayDistributionData, id: \.weekday) { data in
                BarMark(
                    x: .value("星期", DateUtils.weekdayName(data.weekday)),
                    y: .value("分钟", data.minutes)
                )
                .foregroundStyle(weekdayColor(for: data.weekday))
            }
        }
        .frame(height: 150)
    }
    
    // MARK: - 星期颜色
    private func weekdayColor(for weekday: Int) -> Color {
        if weekday == 0 || weekday == 6 {
            return AppColors.warning
        } else {
            return AppColors.primary
        }
    }
}

// MARK: - 统计卡片组件
struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 标签分布圆形统计图（一个圆，中间显示总时长，按标签时长和颜色占据圆弧比例）
struct TagDistributionCircleView: View {
    let tagData: [(tag: String, minutes: Int)]
    let modelContext: ModelContext
    let onTagSelected: (String, Int) -> Void
    
    @Query private var tags: [Tag]
    @State private var selectedTag: String? = nil
    @State private var selectedTagMinutes: Int = 0
    
    private var totalMinutes: Int {
        tagData.reduce(0) { $0 + $1.minutes }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 圆形统计图
            ZStack {
                // 背景圆
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 30)
                    .frame(width: 250, height: 250)
                
                // 标签圆弧
                ForEach(Array(tagData.enumerated()), id: \.offset) { index, data in
                    TagArcView(
                        tag: data.tag,
                        minutes: data.minutes,
                        totalMinutes: totalMinutes,
                        startAngle: startAngle(for: index),
                        endAngle: endAngle(for: index),
                        color: getTagColor(for: data.tag, index: index),
                        isSelected: selectedTag == data.tag
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTag = data.tag
                            selectedTagMinutes = data.minutes
                            onTagSelected(data.tag, data.minutes)
                        }
                    }
                }
                
                // 中心显示：选中标签时显示标签信息，否则显示总时长
                if let selectedTag = selectedTag {
                    VStack(spacing: 8) {
                        Text("\(selectedTag)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        Text("\(selectedTagMinutes) 分钟")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(getTagColor(for: selectedTag, index: tagData.firstIndex(where: { $0.tag == selectedTag }) ?? 0))
                    }
                } else {
                    VStack(spacing: 8) {
                        // 顶部显示"总时长"
                        Text("总时长")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // 中间显示"数字 单位"
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(totalMinutes)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text(totalMinutes >= 60 ? "小时" : "分钟")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(width: 250, height: 250)
            .onTapGesture {
                // 点击圆形图的其他地方，取消选中
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTag = nil
                }
            }
            
            // 标签列表（始终显示在下方）
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedTag == nil ? "点击圆弧查看详情" : "点击圆外区域返回")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(tagData.enumerated()), id: \.offset) { index, data in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(getTagColor(for: data.tag, index: index))
                                    .frame(width: 12, height: 12)
                                Text(data.tag)
                                    .font(.caption)
                                Text("\(data.minutes)分钟")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTag == data.tag ? getTagColor(for: data.tag, index: index).opacity(0.2) : Color(.systemGray5))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .onChange(of: tagData.count) { _, _ in
            // 当数据变化时，取消选中
            selectedTag = nil
        }
        .simultaneousGesture(
            DragGesture()
                .onEnded { _ in
                    // 滑动时取消选中
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTag = nil
                    }
                }
        )
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DeselectTagInCircle"))) { _ in
            // 收到取消选中通知
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTag = nil
            }
        }
    }
    
    // 计算每个标签的起始角度
    private func startAngle(for index: Int) -> Double {
        guard totalMinutes > 0 else { return 0 }
        var angle: Double = -90 // 从顶部开始
        for i in 0..<index {
            let percentage = Double(tagData[i].minutes) / Double(totalMinutes)
            angle += percentage * 360
        }
        return angle
    }
    
    // 计算每个标签的结束角度
    private func endAngle(for index: Int) -> Double {
        guard totalMinutes > 0 else { return 0 }
        let percentage = Double(tagData[index].minutes) / Double(totalMinutes)
        return startAngle(for: index) + percentage * 360
    }
    
    // 获取标签颜色（从Tag模型中获取实际颜色）
    private func getTagColor(for tagName: String, index: Int) -> Color {
        // 首先尝试从Tag模型中获取标签的实际颜色
        if let tag = tags.first(where: { $0.name == tagName }) {
            return Color(hex: tag.color)
        }
        // 如果没有找到，使用默认颜色
        return Color(hex: AppColors.tagColors[index % AppColors.tagColors.count])
    }
}

// MARK: - 标签圆弧视图
struct TagArcView: View {
    let tag: String
    let minutes: Int
    let totalMinutes: Int
    let startAngle: Double
    let endAngle: Double
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    private var startTrim: Double {
        // trim 从 0 到 1，所以需要将角度转换为 0-1 的范围
        // 从 -90 度开始（顶部），所以需要调整
        let normalizedStart = (startAngle + 90) / 360.0
        return max(0, min(1, normalizedStart))
    }
    
    private var endTrim: Double {
        let normalizedEnd = (endAngle + 90) / 360.0
        return max(0, min(1, normalizedEnd))
    }
    
    var body: some View {
        Circle()
            .trim(from: startTrim, to: endTrim)
            .stroke(
                isSelected ? color.opacity(0.8) : color,
                style: StrokeStyle(
                    lineWidth: isSelected ? 35 : 30,
                    lineCap: .round
                )
            )
            .frame(width: 250, height: 250)
            .rotationEffect(.degrees(-90))
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onTap()
                }
            }
    }
}

// MARK: - 标签圆形统计视图（保留用于兼容性）
struct TagCircleView: View {
    let tag: String
    let minutes: Int
    let totalMinutes: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            // 圆形进度环
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: progress)
                
                VStack(spacing: 2) {
                    Text("\(minutes)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("分钟")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // 标签名称
            Text(tag)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: 80)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // 计算进度（基于总时长）
    private var progress: Double {
        guard totalMinutes > 0 else { return 0 }
        return min(1.0, Double(minutes) / Double(totalMinutes))
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: [FocusSession.self, User.self])
}
