//
//  FocusActivityWidget.swift
//  FocusFlow
//
//  Live Activity Widget Extension（用于锁屏和灵动岛显示）
//

import WidgetKit
import SwiftUI
import ActivityKit

// 颜色辅助函数（Widget Extension 中无法访问主应用的扩展）
@available(iOS 16.2, *)
private func colorFromHex(_ hex: String) -> Color {
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
        (a, r, g, b) = (255, 0, 122, 255) // 默认蓝色
    }
    return Color(
        .sRGB,
        red: Double(r) / 255,
        green: Double(g) / 255,
        blue:  Double(b) / 255,
        opacity: Double(a) / 255
    )
}

@available(iOS 16.2, *)
struct FocusActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            // 锁屏显示
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.clear)
        } dynamicIsland: { context in
            // 灵动岛显示
            DynamicIsland {
                // 展开区域
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        // 任务图标
                        Group {
                            if let iconName = context.state.taskIcon, !iconName.isEmpty {
                                Image(systemName: iconName)
                                    .font(.title3)
                                    .foregroundColor(context.state.taskColor != nil ? colorFromHex(context.state.taskColor!) : .blue)
                            } else {
                                Image(systemName: "timer")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("专注中")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let taskName = context.state.taskName, !taskName.isEmpty {
                                Text(taskName)
                                    .font(.headline)
                                    .lineLimit(1)
                                    .foregroundColor(.primary)
                            } else {
                                Text("专注")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        if context.state.isPaused {
                            Text("已暂停")
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else {
                            Text(formatTime(context.state.remainingSeconds))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    // 进度条
                    let taskColor = context.state.taskColor != nil ? colorFromHex(context.state.taskColor!) : .blue
                    ProgressView(value: Double(context.state.totalSeconds - context.state.remainingSeconds), total: Double(context.state.totalSeconds))
                        .progressViewStyle(.linear)
                        .tint(taskColor)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // 底部信息
                    HStack {
                        Text("总时长: \(formatTime(context.state.totalSeconds))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        if context.state.isPaused {
                            Image(systemName: "pause.circle.fill")
                                .foregroundColor(.orange)
                        } else {
                            Image(systemName: "play.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            } compactLeading: {
                // 紧凑模式左侧 - 显示任务图标
                Group {
                    if let iconName = context.state.taskIcon, !iconName.isEmpty {
                        Image(systemName: iconName)
                            .font(.caption)
                            .foregroundColor(context.state.taskColor != nil ? colorFromHex(context.state.taskColor!) : (context.state.isPaused ? .orange : .blue))
                    } else {
                        Image(systemName: context.state.isPaused ? "pause.circle" : "timer")
                            .font(.caption)
                            .foregroundColor(context.state.isPaused ? .orange : .blue)
                    }
                }
            } compactTrailing: {
                // 紧凑模式右侧 - 显示剩余时间
                Text(formatTime(context.state.remainingSeconds))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            } minimal: {
                // 最小模式 - 显示任务图标
                Group {
                    if let iconName = context.state.taskIcon, !iconName.isEmpty {
                        Image(systemName: iconName)
                            .font(.caption)
                            .foregroundColor(context.state.taskColor != nil ? colorFromHex(context.state.taskColor!) : (context.state.isPaused ? .orange : .blue))
                    } else {
                        Image(systemName: context.state.isPaused ? "pause.circle" : "timer")
                            .font(.caption)
                            .foregroundColor(context.state.isPaused ? .orange : .blue)
                    }
                }
            }
        }
    }
}


// 格式化时间辅助函数
@available(iOS 16.2, *)
private func formatTime(_ seconds: Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    let secs = seconds % 60
    
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, secs)
    } else {
        return String(format: "%d:%02d", minutes, secs)
    }
}

// 锁屏显示视图
@available(iOS 16.2, *)
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<FocusActivityAttributes>
    
    var body: some View {
        HStack(spacing: 12) {
            // 左侧图标
            ZStack {
                Circle()
                    .fill(context.state.isPaused ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: context.state.isPaused ? "pause.circle.fill" : "timer")
                    .font(.title2)
                    .foregroundColor(context.state.isPaused ? .orange : .blue)
            }
            
            // 中间信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("专注中")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if context.state.isPaused {
                        Text("已暂停")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                if let taskName = context.state.taskName {
                    Text(taskName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 进度条
                ProgressView(value: Double(context.state.totalSeconds - context.state.remainingSeconds), total: Double(context.state.totalSeconds))
                    .progressViewStyle(.linear)
                    .tint(context.state.isPaused ? .orange : .blue)
            }
            
            Spacer()
            
            // 右侧时间
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatTime(context.state.remainingSeconds))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("剩余")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // 格式化时间
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

