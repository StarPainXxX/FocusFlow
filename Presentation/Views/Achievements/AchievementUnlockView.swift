//
//  AchievementUnlockView.swift
//  FocusFlow
//
//  成就解锁动画视图
//

import SwiftUI

struct AchievementUnlockView: View {
    let achievement: Achievement
    let onDismiss: () -> Void
    
    @State private var animationScale: CGFloat = 0.3
    @State private var animationOpacity: Double = 0
    @State private var showConfetti = false
    @State private var rotationAngle: Double = 0
    @State private var sparkleOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }
            
            // 解锁内容
            VStack(spacing: 30) {
                // 成就图标和动画
                ZStack {
                    // 背景光晕效果
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "#FFD700").opacity(0.3),
                                    Color(hex: "#FFD700").opacity(0.0)
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .scaleEffect(animationScale)
                        .opacity(animationOpacity)
                    
                    // 外圈旋转圆环
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#FFD700"),
                                        Color(hex: "#FFA500"),
                                        Color(hex: "#FFD700")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )
                            .frame(width: 140 + CGFloat(index * 20), height: 140 + CGFloat(index * 20))
                            .rotationEffect(.degrees(rotationAngle + Double(index * 120)))
                            .opacity(animationOpacity)
                    }
                    
                    // 中心成就图标
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#FFD700"),
                                        Color(hex: "#FFA500")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: Color(hex: "#FFD700").opacity(0.5), radius: 20)
                            .scaleEffect(animationScale)
                        
                        Image(systemName: achievement.icon)
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                            .scaleEffect(animationScale)
                    }
                    
                    // 闪光效果
                    if showConfetti {
                        ForEach(0..<12) { index in
                            Circle()
                                .fill(Color(hex: "#FFD700"))
                                .frame(width: 8, height: 8)
                                .offset(
                                    x: cos(Double(index) * .pi / 6) * sparkleOffset,
                                    y: sin(Double(index) * .pi / 6) * sparkleOffset
                                )
                                .opacity(animationOpacity)
                        }
                    }
                }
                .frame(height: 300)
                
                // 解锁文字
                VStack(spacing: 15) {
                    Text("🎉 成就解锁！")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(animationOpacity)
                    
                    Text(achievement.name)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .opacity(animationOpacity)
                    
                    Text(achievement.achievementDescription)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .opacity(animationOpacity)
                        .padding(.horizontal, 40)
                }
                
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
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
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
                    .shadow(radius: 30)
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
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        // 第三阶段：闪光效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                showConfetti = true
                sparkleOffset = 100
            }
        }
        
        // 第四阶段：轻微脉动
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
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
    AchievementUnlockView(
        achievement: Achievement(
            userId: "test",
            achievementType: .duration,
            name: "专注达人",
            achievementDescription: "累计专注100小时",
            icon: "flame.fill",
            requirement: "{\"totalMinutes\": 6000}"
        ),
        onDismiss: {}
    )
}

