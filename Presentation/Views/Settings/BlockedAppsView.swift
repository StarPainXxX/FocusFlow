//
//  BlockedAppsView.swift
//  FocusFlow
//
//  屏蔽应用列表管理视图
//

import SwiftUI

struct BlockedAppsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settingsManager = SettingsManager.shared
    @State private var searchText = ""
    @State private var showSystemApps = false
    
    // 模拟应用列表（实际应用中需要获取设备上安装的应用列表）
    // 注意：iOS限制，无法直接获取所有应用列表，这里提供常见应用
    private let commonApps: [(name: String, bundleId: String, isSystem: Bool)] = [
        // 系统应用
        ("电话", "com.apple.mobilephone", true),
        ("邮件", "com.apple.mobilemail", true),
        ("Safari", "com.apple.mobilesafari", true),
        ("计算器", "com.apple.calculator", true),
        ("相机", "com.apple.camera", true),
        ("时钟", "com.apple.mobiletimer", true),
        ("日历", "com.apple.mobilecal", true),
        ("备忘录", "com.apple.mobilenotes", true),
        ("地图", "com.apple.mobilemaps", true),
        
        // 常见第三方应用
        ("微信", "com.tencent.xin", false),
        ("QQ", "com.tencent.mqq", false),
        ("微博", "com.sina.weibo", false),
        ("抖音", "com.ss.iphone.ugc.TikTok", false),
        ("快手", "com.smile.gifmaker", false),
        ("Bilibili", "tv.danmaku.bili", false),
        ("爱奇艺", "com.qiyi.iphone", false),
        ("优酷", "com.youku.iphone", false),
        ("腾讯视频", "com.tencent.qqlive", false),
        ("王者荣耀", "com.tencent.tmgp.sgame", false),
        ("和平精英", "com.tencent.tmgp.pubgmhd", false),
        ("原神", "com.miHoYo.bh3rd", false),
        ("Steam", "com.valvesoftware.steamlink", false),
        ("Epic Games", "com.epicgames.portal", false),
        ("Netflix", "com.netflix.Netflix", false),
        ("YouTube", "com.google.ios.youtube", false),
        ("Instagram", "com.burbn.instagram", false),
        ("Facebook", "com.facebook.Facebook", false),
        ("Twitter", "com.atebits.Tweetie2", false),
        ("WhatsApp", "net.whatsapp.WhatsApp", false),
        ("Telegram", "ph.telegra.Telegraph", false),
        ("Discord", "com.hammerandchisel.discord", false),
        ("Spotify", "com.spotify.client", false),
        ("网易云音乐", "com.netease.cloudmusic", false),
        ("QQ音乐", "com.tencent.QQMusic", false),
        ("酷狗音乐", "com.kugou.hy", false),
        ("喜马拉雅", "com.ximalaya.ting", false),
        ("知乎", "com.zhihu.ios", false),
        ("小红书", "com.xingin.xhs", false),
        ("淘宝", "com.taobao.taobao4iphone", false),
        ("京东", "com.jingdong.app.mall", false),
        ("拼多多", "com.xunmeng.pinduoduo", false),
        ("美团", "com.sankuai.meituan", false),
        ("饿了么", "me.ele.iphone", false),
        ("滴滴出行", "com.didi.soda.galaxy", false),
        ("高德地图", "com.autonavi.minimap", false),
        ("百度地图", "com.baidu.BaiduMap", false),
    ]
    
    private var filteredApps: [(name: String, bundleId: String, isSystem: Bool)] {
        var apps = commonApps
        
        // 如果搜索文本不为空，进行过滤
        if !searchText.isEmpty {
            apps = apps.filter { app in
                app.name.localizedCaseInsensitiveContains(searchText) ||
                app.bundleId.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 如果显示系统应用选项关闭，过滤系统应用
        if !showSystemApps {
            apps = apps.filter { !$0.isSystem }
        }
        
        return apps
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索栏
                SearchBar(text: $searchText)
                
                // 选项
                VStack(spacing: 10) {
                    Toggle("显示系统应用", isOn: $showSystemApps)
                        .padding(.horizontal)
                    
                    Toggle("屏蔽所有应用（除了系统应用）", isOn: $settingsManager.blockAllAppsExceptSystem)
                        .padding(.horizontal)
                        .onChange(of: settingsManager.blockAllAppsExceptSystem) { _, _ in
                            settingsManager.saveSettings()
                        }
                }
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                
                // 应用列表
                List {
                    ForEach(Array(filteredApps.enumerated()), id: \.element.bundleId) { index, app in
                        HStack {
                            // 应用图标占位符
                            Circle()
                                .fill(app.isSystem ? Color.blue : Color.gray)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(app.name.prefix(1))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(app.name)
                                    .font(.headline)
                                
                                if app.isSystem {
                                    Text("系统应用")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                } else {
                                    Text(app.bundleId)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if settingsManager.blockedApps.contains(app.bundleId) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleApp(app.bundleId)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("屏蔽应用")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        settingsManager.saveSettings()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleApp(_ bundleId: String) {
        if settingsManager.blockedApps.contains(bundleId) {
            settingsManager.blockedApps.removeAll { $0 == bundleId }
        } else {
            settingsManager.blockedApps.append(bundleId)
        }
        settingsManager.saveSettings()
    }
}

// MARK: - 搜索栏组件
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索应用", text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    BlockedAppsView()
}

