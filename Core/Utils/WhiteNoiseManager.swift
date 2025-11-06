//
//  WhiteNoiseManager.swift
//  FocusFlow
//
//  白噪音管理器（专注时的背景音乐）
//

import Foundation
import AVFoundation
import Combine

@MainActor
class WhiteNoiseManager: ObservableObject {
    static let shared = WhiteNoiseManager()
    
    @Published var isPlaying = false
    @Published var currentNoise: WhiteNoiseType? = nil
    @Published var volume: Float = 0.5 // 默认音量 50%
    
    private var audioPlayer: AVAudioPlayer?
    
    // 可用的白噪音类型（对应 Music 文件夹中的音频文件）
    enum WhiteNoiseType: String, CaseIterable {
        case none = "none"
        case rain = "rain"
        case ocean = "ocean"
        case fire = "fire"
        case night = "night"
        case rainBirds = "rain&birds"
        
        var displayName: String {
            switch self {
            case .none: return "无"
            case .rain: return "雨声"
            case .ocean: return "海浪"
            case .fire: return "篝火"
            case .night: return "夜晚"
            case .rainBirds: return "雨声与鸟鸣"
            }
        }
        
        var fileName: String {
            switch self {
            case .none:
                return ""
            case .rain:
                return "rain"
            case .ocean:
                return "ocean"
            case .fire:
                return "fire"
            case .night:
                return "night"
            case .rainBirds:
                return "rain&birds"
            }
        }
        
        init?(from string: String) {
            self.init(rawValue: string)
        }
    }
    
    private init() {
        setupAudioSession()
    }
    
    /// 设置音频会话
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            Logger.error("设置音频会话失败: \(error.localizedDescription)", category: .app)
        }
    }
    
    /// 播放白噪音
    func play(_ noiseType: WhiteNoiseType) {
        guard noiseType != .none else {
            stop()
            return
        }
        
        // 先停止当前播放
        stop()
        
        currentNoise = noiseType
        isPlaying = true
        
        // 播放音频文件
        playAudioFile(noiseType)
        
        Logger.info("开始播放白噪音: \(noiseType.displayName)", category: .app)
    }
    
    /// 根据字符串播放白噪音
    func play(noiseTypeString: String) {
        guard let noiseType = WhiteNoiseType(from: noiseTypeString) else {
            stop()
            return
        }
        play(noiseType)
    }
    
    /// 停止播放
    func stop() {
        // 清理资源
        audioPlayer?.stop()
        audioPlayer = nil
        
        isPlaying = false
        currentNoise = nil
        
        Logger.info("停止播放白噪音", category: .app)
    }
    
    /// 设置音量
    func setVolume(_ volume: Float) {
        self.volume = max(0.0, min(1.0, volume))
        audioPlayer?.volume = self.volume
    }
    
    // MARK: - 播放音频文件
    private func playAudioFile(_ noiseType: WhiteNoiseType) {
        guard noiseType != .none else {
            stop()
            return
        }
        
        let fileName = noiseType.fileName
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            Logger.error("找不到音频文件: \(fileName).mp3", category: .app)
            stop()
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // 无限循环
            audioPlayer?.volume = volume
            audioPlayer?.play()
        } catch {
            Logger.error("播放音频文件失败: \(error.localizedDescription)", category: .app)
            stop()
        }
    }
}

