//
//  AppColors.swift
//  FocusFlow
//
//  应用颜色
//

import SwiftUI

struct AppColors {
    // MARK: - 主色调
    static let primary = Color(hex: "#007AFF")
    static let secondary = Color(hex: "#5856D6")
    static let accent = Color(hex: "#FF9500")
    
    // MARK: - 功能色
    static let success = Color(hex: "#34C759")
    static let warning = Color(hex: "#FF9500")
    static let error = Color(hex: "#FF3B30")
    
    // MARK: - 背景色
    static let background = Color(uiColor: .systemBackground)
    static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)
    
    // MARK: - 文字色
    static let primaryText = Color(uiColor: .label)
    static let secondaryText = Color(uiColor: .secondaryLabel)
    static let tertiaryText = Color(uiColor: .tertiaryLabel)
    
    // MARK: - 标签颜色
    static let tagColors: [String] = [
        "#007AFF", // 蓝色
        "#34C759", // 绿色
        "#FF9500", // 橙色
        "#FF2D55", // 粉色
        "#5856D6", // 紫色
        "#FF3B30", // 红色
        "#FFCC00", // 黄色
        "#5AC8FA", // 浅蓝
        "#AF52DE", // 紫罗兰
        "#FF9500", // 橙色
        "#00C7BE", // 青色
        "#8E8E93"  // 灰色
    ]
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

