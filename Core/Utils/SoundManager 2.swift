//
//  SoundManager.swift
//  FocusFlow
//
//  声音管理工具
//

import Foundation
import AudioToolbox

class SoundManager {
    static let shared = SoundManager()
    
    private init() {}
    
    /// 播放系统声音
    /// - Parameter soundID: 系统声音ID，默认为系统提示音（1057）
    func playSystemSound(soundID: SystemSoundID = 1057) {
        AudioServicesPlaySystemSound(soundID)
    }
    
    /// 根据声音名称播放系统声音
    /// - Parameter soundName: 声音名称（default, bell, chime, success, complete）
    func playSound(named soundName: String) {
        let soundID: SystemSoundID
        
        switch soundName {
        case "default":
            soundID = 1057 // 默认提示音
        case "bell":
            soundID = 1054 // 钟声
        case "chime":
            soundID = 1053 // 铃声
        case "success":
            soundID = 1055 // 成功音
        case "complete":
            soundID = 1056 // 完成音
        default:
            soundID = 1057 // 默认提示音
        }
        
        AudioServicesPlaySystemSound(soundID)
    }
    
    /// 播放专注完成声音
    func playFocusCompleteSound() {
        let settings = SettingsManager.shared
        guard settings.soundEnabled else { return }
        
        playSound(named: settings.selectedCompleteSound)
    }
    
    /// 播放休息完成声音
    func playBreakCompleteSound() {
        let settings = SettingsManager.shared
        guard settings.soundEnabled else { return }
        
        playSound(named: settings.selectedBreakCompleteSound)
    }
}

