//
//  TagsManagementView.swift
//  FocusFlow
//
//  标签管理视图
//

import SwiftUI
import SwiftData

struct TagsManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var tags: [Tag]
    @State private var showTagForm = false
    @State private var editingTag: Tag?
    
    private var defaultTags: [Tag] {
        tags.filter { $0.isDefault }
    }
    
    private var customTags: [Tag] {
        tags.filter { !$0.isDefault }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 预设标签
                if !defaultTags.isEmpty {
                    Section("预设标签") {
                        ForEach(defaultTags) { tag in
                            TagRow(tag: tag)
                        }
                    }
                }
                
                // 自定义标签
                Section("自定义标签") {
                    if customTags.isEmpty {
                        Text("暂无自定义标签")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(customTags) { tag in
                            TagRow(tag: tag)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deleteTag(tag)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        editingTag = tag
                                        showTagForm = true
                                    } label: {
                                        Label("编辑", systemImage: "pencil")
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("标签管理")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editingTag = nil
                        showTagForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showTagForm) {
                TagFormView(tag: editingTag)
            }
            .onAppear {
                initializeDefaultTagsIfNeeded()
            }
        }
    }
    
    // MARK: - 初始化默认标签
    private func initializeDefaultTagsIfNeeded() {
        // 使用 AchievementUtils 统一初始化默认标签，避免重复
        // 这个方法会检查是否已存在，只创建不存在的标签
        AchievementUtils.initializeDefaultTags(context: modelContext)
    }
    
    // MARK: - 删除标签
    private func deleteTag(_ tag: Tag) {
        modelContext.delete(tag)
        do {
            try modelContext.save()
            Logger.info("删除标签成功: \(tag.name)", category: .data)
        } catch {
            Logger.error("删除标签失败: \(error.localizedDescription)", category: .data)
        }
    }
}

// MARK: - 标签行
struct TagRow: View {
    let tag: Tag
    
    var body: some View {
        HStack {
            // 颜色指示器
            Circle()
                .fill(Color(hex: tag.color))
                .frame(width: 20, height: 20)
            
            // 标签名称
            Text(tag.name)
                .font(.body)
            
            Spacer()
            
            // 使用次数
            if tag.usageCount > 0 {
                Text("\(tag.usageCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            
            // 图标
            if let icon = tag.icon {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 标签表单视图
struct TagFormView: View {
    let tag: Tag?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedColor: String = "#007AFF"
    @State private var selectedIcon: String? = nil
    
    private let availableColors = AppColors.tagColors
    private let availableIcons = [
        // 学习相关
        "book.fill", "book.closed.fill", "graduationcap.fill", "pencil", "highlighter",
        // 工作相关
        "briefcase.fill", "laptopcomputer", "keyboard", "desktopcomputer", "printer.fill",
        // 创作相关
        "paintbrush.fill", "paintpalette.fill", "music.note", "camera.fill", "photo.fill",
        // 运动相关
        "dumbbell.fill", "figure.run", "bicycle", "sportscourt.fill", "soccerball",
        // 游戏相关
        "gamecontroller.fill", "dice.fill", "puzzlepiece.fill",
        // 生活相关
        "heart.fill", "star.fill", "flame.fill", "leaf.fill", "moon.fill", "sun.max.fill",
        "cup.and.saucer.fill", "bed.double.fill", "house.fill", "car.fill",
        // 其他
        "target", "bolt.fill", "sparkles", "wand.and.stars", "chart.bar.fill",
        "message.fill", "phone.fill", "envelope.fill", "calendar", "clock.fill",
        "tag.fill", "bell.fill", "flag.fill", "bookmark.fill", "paperclip"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("标签名称", text: $name)
                }
                
                Section("颜色") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(Array(availableColors.enumerated()), id: \.offset) { index, colorHex in
                                ColorSelector(
                                    colorHex: colorHex,
                                    isSelected: selectedColor == colorHex
                                ) {
                                    selectedColor = colorHex
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section("图标（可选）") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            // 无图标选项
                            IconSelector(
                                icon: nil,
                                isSelected: selectedIcon == nil
                            ) {
                                selectedIcon = nil
                            }
                            
                            ForEach(availableIcons, id: \.self) { icon in
                                IconSelector(
                                    icon: icon,
                                    isSelected: selectedIcon == icon
                                ) {
                                    selectedIcon = icon
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle(tag == nil ? "新建标签" : "编辑标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTag()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let tag = tag {
                    name = tag.name
                    selectedColor = tag.color
                    selectedIcon = tag.icon
                }
            }
        }
    }
    
    private func saveTag() {
        if let tag = tag {
            // 更新现有标签
            tag.name = name
            tag.color = selectedColor
            tag.icon = selectedIcon
            tag.updatedAt = Date()
        } else {
            // 创建新标签
            let newTag = Tag(
                userId: "default-user",
                name: name,
                color: selectedColor,
                icon: selectedIcon,
                isDefault: false
            )
            modelContext.insert(newTag)
        }
        
        do {
            try modelContext.save()
            dismiss()
            Logger.info("保存标签成功: \(name)", category: .data)
        } catch {
            Logger.error("保存标签失败: \(error.localizedDescription)", category: .data)
        }
    }
}

// MARK: - 颜色选择器
struct ColorSelector: View {
    let colorHex: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: 40, height: 40)
                
                if isSelected {
                    Circle()
                        .stroke(Color.primary, lineWidth: 3)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "checkmark")
                        .foregroundColor(.primary)
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 图标选择器
struct IconSelector: View {
    let icon: String?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? AppColors.primary.opacity(0.2) : Color(.systemGray5))
                    .frame(width: 44, height: 44)
                
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(isSelected ? AppColors.primary : .secondary)
                        .font(.title3)
                } else {
                    Text("无")
                        .font(.caption)
                        .foregroundColor(isSelected ? AppColors.primary : .secondary)
                }
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.primary, lineWidth: 2)
                        .frame(width: 44, height: 44)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TagsManagementView()
        .modelContainer(for: [Tag.self])
}

