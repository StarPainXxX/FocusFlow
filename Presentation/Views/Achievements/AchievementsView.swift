//
//  AchievementsView.swift
//  FocusFlow
//
//  成就视图
//

import SwiftUI

struct AchievementsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("成就页面")
                        .font(.title)
                        .padding()
                    
                    Text("功能开发中...")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("成就")
        }
    }
}

#Preview {
    AchievementsView()
}

