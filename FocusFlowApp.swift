//
//  FocusFlowApp.swift
//  FocusFlow
//
//  Created on 2024
//

import SwiftUI
import SwiftData

@main
struct FocusFlowApp: App {
    let container: ModelContainer
    
    init() {
        container = SwiftDataSource.createModelContainer()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

