//
//  TagPickerView.swift
//  FocusFlow
//
//  标签选择器视图
//

import SwiftUI
import SwiftData

struct TagPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var tags: [Tag]
    @Binding var selectedTags: [String]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(tags) { tag in
                    TagPickerRow(
                        tag: tag,
                        isSelected: selectedTags.contains(tag.name)
                    ) {
                        toggleTag(tag.name)
                    }
                }
            }
            .navigationTitle("选择标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleTag(_ tagName: String) {
        // 每个任务只能有一个标签，所以选择新标签时，先清空之前的标签
        if selectedTags.contains(tagName) {
            selectedTags.removeAll { $0 == tagName }
        } else {
            // 如果选择了新标签，先清空所有标签，再添加新标签
            selectedTags = [tagName]
        }
    }
}

// MARK: - 标签选择行
struct TagPickerRow: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // 颜色指示器
                Circle()
                    .fill(Color(hex: tag.color))
                    .frame(width: 20, height: 20)
                
                // 标签名称
                Text(tag.name)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 选中标记
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(AppColors.primary)
                        .fontWeight(.bold)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TagPickerView(selectedTags: .constant([]))
        .modelContainer(for: [Tag.self])
}

