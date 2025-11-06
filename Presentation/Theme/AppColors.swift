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
    
    // MARK: - 标签颜色（扩展颜色选项，包含图5中的颜色系列）
    static let tagColors: [String] = [
        // 基础颜色
        "#007AFF", // 蓝色
        "#34C759", // 绿色
        "#FF9500", // 橙色
        "#FF2D55", // 粉色
        "#5856D6", // 紫色
        "#FF3B30", // 红色
        "#FFCC00", // 黄色
        "#5AC8FA", // 浅蓝
        "#AF52DE", // 紫罗兰
        "#00C7BE", // 青色
        "#8E8E93", // 灰色
        
        // 推荐颜色系列
        "#FF6B6B", // 珊瑚红
        "#FFA500", // 亮橙色
        "#FFD700", // 亮黄色
        "#90EE90", // 酸橙绿
        "#32CD32", // 鲜绿色
        "#87CEEB", // 天蓝色
        "#9370DB", // 深紫色
        
        // 马卡龙色系
        "#FFB6C1", // 浅珊瑚粉
        "#FFC0CB", // 淡粉色
        "#FFF8DC", // 奶油色
        "#98FB98", // 薄荷绿
        "#AFEEEE", // 浅青绿色
        "#B0E0E6", // 粉蓝色
        "#DDA0DD", // 薰衣草紫
        "#FFB6C1", // 浅玫瑰粉
        
        // 莫兰迪色系
        "#BC8F8F", // 灰褐色
        "#D2B48C", // 灰橙色
        "#9ACD32", // 灰绿色
        "#5F9EA0", // 灰青色
        "#4682B4", // 灰蓝色
        "#B0C4DE", // 灰薰衣草
        "#DEB887", // 灰玫瑰色
        
        // 洛可可色系
        "#CD5C5C", // 灰玫瑰红
        "#FF7F50", // 焦橙色
        "#DAA520", // 淡金色
        "#9FAF8F", // 鼠尾草绿
        "#008B8B", // 深青色
        "#2F4F4F", // 灰海军蓝
        "#696969", // 灰紫色
        "#A0522D", // 灰红褐色
        
        // 经典色系
        "#FF6347", // 番茄红
        "#FF8C00", // 深橙色
        "#FFD700", // 金色
        "#ADFF2F", // 黄绿色
        "#00FA9A", // 中春绿
        "#00CED1", // 深青色
        "#8A2BE2", // 蓝紫色
        "#FF1493", // 深粉色
        
        // 孟菲斯色系
        "#DC143C", // 深红色
        "#FF7F50", // 珊瑚橙
        "#FFD700", // 金色
        "#00CED1", // 深青色
        "#40E0D0", // 青绿色
        "#9370DB", // 中紫色
        "#E6E6FA", // 淡紫色
        "#FF69B4"  // 热粉色
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
            // 默认返回黑色（如果格式不正确）
            (a, r, g, b) = (255, 0, 0, 0)
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

