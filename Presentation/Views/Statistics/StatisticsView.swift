//
//  StatisticsView.swift
//  FocusFlow
//
//  统计视图
//

import SwiftUI

struct StatisticsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("统计页面")
                        .font(.title)
                        .padding()
                    
                    Text("功能开发中...")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("统计")
        }
    }
}

#Preview {
    StatisticsView()
}

