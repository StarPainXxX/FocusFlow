//
//  AchievementsView.swift
//  FocusFlow
//
//  成就视图
//

import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var achievements: [Achievement]
    @Query private var users: [User]
    @State private var selectedCategory: AchievementType?
    @State private var showingUnlockAnimation: Achievement?
    
    private var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return achievements.filter { $0.achievementType == category }
        }
        return achievements
    }
    
    private var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 总览卡片
                    overviewSection
                    
                    // 分类筛选
                    categoryFilter
                    
                    // 成就列表
                    achievementsGrid
                }
                .padding()
            }
            .navigationTitle("成就")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                // 成就解锁动画
                if let achievement = showingUnlockAnimation {
                    AchievementUnlockView(achievement: achievement) {
                        showingUnlockAnimation = nil
                    }
                }
            }
            .onAppear {
                // 延迟初始化默认成就，避免阻塞UI
                _Concurrency.Task { @MainActor in
                    try? await _Concurrency.Task.sleep(nanoseconds: 50_000_000) // 0.05秒
                    
                    let descriptor = FetchDescriptor<Achievement>()
                    if let achievements = try? modelContext.fetch(descriptor), achievements.isEmpty {
                        AchievementUtils.initializeDefaultAchievements(context: modelContext)
                    }
                }
                
                // 监听新解锁的成就
                checkForNewlyUnlockedAchievements()
            }
            .onChange(of: achievements) { oldAchievements, newAchievements in
                // 检测新解锁的成就
                let newlyUnlocked = newAchievements.filter { achievement in
                    achievement.isUnlocked &&
                    oldAchievements.first(where: { $0.id == achievement.id })?.isUnlocked == false
                }
                
                if let newAchievement = newlyUnlocked.first {
                    showingUnlockAnimation = newAchievement
                }
            }
        }
    }
    
    // MARK: - 总览卡片
    private var overviewSection: some View {
        VStack(spacing: 15) {
            if let user = users.first {
                HStack(spacing: 30) {
                    VStack {
                        Text("\(user.level)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(AppColors.primary)
                        Text("等级")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(user.exp)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.orange)
                        Text("经验值")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(unlockedCount)/\(achievements.count)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.green)
                        Text("成就解锁")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - 分类筛选
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterButton(
                    title: "全部",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                ForEach(AchievementType.allCases, id: \.self) { category in
                    FilterButton(
                        title: categoryName(category),
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - 成就网格
    private var achievementsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            ForEach(filteredAchievements) { achievement in
                AchievementCard(achievement: achievement)
            }
        }
    }
    
    private func categoryName(_ type: AchievementType) -> String {
        switch type {
        case .duration:
            return "时长"
        case .streak:
            return "连续"
        case .pomodoro:
            return "番茄"
        case .special:
            return "特殊"
        }
    }
    
    // MARK: - 检查新解锁的成就
    private func checkForNewlyUnlockedAchievements() {
        // 这个方法在视图出现时检查是否有刚解锁的成就
        // 实际解锁逻辑在 StatisticsUtils 中处理
    }
}

// MARK: - 成就卡片
struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color(hex: "#FFD700") : Color(.systemGray4))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.title)
                    .foregroundColor(achievement.isUnlocked ? .black : .gray)
            }
            
            Text(achievement.name)
                .font(.caption)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if achievement.isUnlocked, let unlockedAt = achievement.unlockedAt {
                Text(DateUtils.formatDate(unlockedAt, format: "MM-dd"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text("未解锁")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }
}

extension AchievementType: CaseIterable {
    static var allCases: [AchievementType] {
        return [.duration, .streak, .pomodoro, .special]
    }
}

#Preview {
    AchievementsView()
        .modelContainer(for: [Achievement.self, User.self])
}
