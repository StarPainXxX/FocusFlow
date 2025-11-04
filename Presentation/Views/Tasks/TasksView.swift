//
//  TasksView.swift
//  FocusFlow
//
//  任务视图
//

import SwiftUI

struct TasksView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("任务页面")
                        .font(.title)
                        .padding()
                    
                    Text("功能开发中...")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("任务")
        }
    }
}

#Preview {
    TasksView()
}

