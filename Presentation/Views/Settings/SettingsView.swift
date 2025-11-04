//
//  SettingsView.swift
//  FocusFlow
//
//  设置视图
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("设置页面")
                        .font(.title)
                        .padding()
                    
                    Text("功能开发中...")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("设置")
        }
    }
}

#Preview {
    SettingsView()
}

