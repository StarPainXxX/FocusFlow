//
//  FocusFlowWidgetBundle.swift
//  FocusFlowWidget
//
//  Created by JoelChan on 2025/11/5.
//

import WidgetKit
import SwiftUI
import ActivityKit

@main
struct FocusFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusFlowWidget()
        FocusFlowWidgetControl()
        if #available(iOS 16.2, *) {
            FocusActivityWidget()
        }
    }
}
