//
//  SwiftDataSource.swift
//  FocusFlow
//
//  SwiftData数据源
//

import Foundation
import SwiftData

class SwiftDataSource {
    static let shared = SwiftDataSource()
    
    private init() {}
    
    /// 创建ModelContainer
    static func createModelContainer() -> ModelContainer {
        let schema = Schema([
            FocusSession.self,
            Task.self,
            Tag.self,
            User.self,
            Achievement.self
        ])
        
        // 配置存储路径，使用默认位置让系统自动处理
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            // 确保容器正确初始化
            _ = container.mainContext
            
            return container
        } catch {
            // 如果创建失败，尝试使用内存存储作为后备方案
            print("⚠️ 无法创建持久化存储，使用内存存储: \(error.localizedDescription)")
            let inMemoryConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            do {
                return try ModelContainer(
                    for: schema,
                    configurations: [inMemoryConfiguration]
                )
            } catch {
                fatalError("无法创建ModelContainer: \(error)")
            }
        }
    }
}

