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
    /// - Parameter soundName: 声音名称（Mac系统声音：boop, breeze, bubble等）
    func playSound(named soundName: String) {
        let soundID: SystemSoundID
        
        switch soundName {
        case "default":
            soundID = 1057 // 默认提示音
        case "boop":
            soundID = 1104 // Boop
        case "breeze":
            soundID = 1103 // Breeze
        case "bubble":
            soundID = 1105 // Bubble
        case "crystal":
            soundID = 1106 // Crystal
        case "funky":
            soundID = 1107 // Funky
        case "heroine":
            soundID = 1108 // Heroine
        case "jump":
            soundID = 1102 // Jump
        case "mezzo":
            soundID = 1109 // Mezzo
        case "pebble":
            soundID = 1110 // Pebble
        case "pluck":
            soundID = 1111 // Pluck
        case "pong":
            soundID = 1112 // Pong
        case "sonar":
            soundID = 1113 // Sonar
        case "sonumi":
            soundID = 1114 // Sonumi
        case "submerge":
            soundID = 1115 // Submerge
        case "bell":
            soundID = 1005 // 钟声
        case "chime":
            soundID = 1006 // 铃声
        case "success":
            soundID = 1054 // 成功音
        case "complete":
            soundID = 1055 // 完成音
        default:
            soundID = 1057 // 默认提示音
        }
        
        // 使用 AudioServicesPlaySystemSoundWithCompletion 以便在播放失败时使用默认声音
        AudioServicesPlaySystemSoundWithCompletion(soundID) {
            // 播放完成回调
        }
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

