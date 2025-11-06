//
//  FocusCompletionView.swift
//  FocusFlow
//
//  专注完成庆祝视图
//

import SwiftUI

struct FocusCompletionView: View {
    let duration: Int
    let taskName: String?
    let onDismiss: () -> Void
    
    @State private var animationScale: CGFloat = 0.5
    @State private var animationOpacity: Double = 0
    @State private var showConfetti = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }
            
            // 庆祝内容
            VStack(spacing: 30) {
                // 庆祝图标和文字
                VStack(spacing: 20) {
                    // 圆环爆炸效果
                    ZStack {
                        // 外圈圆环
                        ForEach(0..<8) { index in
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 200, height: 200)
                                .scaleEffect(animationScale)
                                .opacity(animationOpacity)
                                .rotationEffect(.degrees(Double(index) * 45 + rotationAngle))
                        }
                        
                        // 中心图标
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [AppColors.primary, AppColors.success],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .scaleEffect(animationScale)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                                .scaleEffect(animationScale)
                        }
                    }
                    .frame(height: 250)
                    
                    // 完成文字
                    VStack(spacing: 10) {
                        Text("专注完成！")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(animationOpacity)
                        
                        Text("\(DateUtils.formatDuration(duration))")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .opacity(animationOpacity)
                        
                        if let taskName = taskName {
                            Text(taskName)
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.8))
                                .opacity(animationOpacity)
                        }
                    }
                }
                .padding(.top, 40)
                
                Spacer()
                
                // 关闭按钮
                Button(action: {
                    dismissWithAnimation()
                }) {
                    Text("太棒了！")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primary)
                        .cornerRadius(12)
                }
                .opacity(animationOpacity)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 20)
            )
            .padding(40)
            .scaleEffect(animationScale)
            .opacity(animationOpacity)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // 第一阶段：缩放和淡入
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            animationScale = 1.0
            animationOpacity = 1.0
        }
        
        // 第二阶段：旋转动画
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        // 第三阶段：轻微脉动
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            animationScale = 1.05
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            animationScale = 0.8
            animationOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

#Preview {
    FocusCompletionView(
        duration: 25,
        taskName: "学习 SwiftUI",
        onDismiss: {}
    )
}

