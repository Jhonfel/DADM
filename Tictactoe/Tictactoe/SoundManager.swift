//
//  SoundManager.swift
//  RetoTicTacToe
//
//  Created by Jhon Felipe Delgado on 16/11/24.
//

import Foundation
import AudioToolbox

enum SystemSoundID: UInt32 {
    case tap = 1104        // Sonido de toque
    case success = 1325    // Sonido de éxito
    case error = 1073      // Sonido de error
}

class SoundManager {
    static func playSound(_ sound: SystemSoundID) {
        AudioServicesPlaySystemSound(sound.rawValue)
    }
}
