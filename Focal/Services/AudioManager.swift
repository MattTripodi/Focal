//
//  AudioManager.swift
//  Focal
//
//  Created by Matthew Tripodi on 6/30/26.
//

import Foundation
import AVFoundation
import Observation

@Observable
@MainActor
final class AudioManager {

    // MARK: - Sound Catalog

    enum Sound: String, CaseIterable, Identifiable {
        case none       = "None"
        case rain       = "Rain"         // free tier
        case whiteNoise = "White Noise"  // premium
        case cafe       = "Café"         // premium
        case forest     = "Forest"       // premium
        case ocean      = "Ocean"        // premium

        var id: String { rawValue }
        var isPremium: Bool { self != .none && self != .rain }

        var systemImage: String {
            switch self {
            case .none:       return "speaker.slash"
            case .rain:       return "cloud.rain"
            case .whiteNoise: return "waveform"
            case .cafe:       return "cup.and.saucer"
            case .forest:     return "leaf"
            case .ocean:      return "water.waves"
            }
        }

        /// Bundle filename without extension. Add these .mp3s to the Focal target.
        var filename: String? {
            switch self {
            case .none:       return nil
            case .rain:       return "sound_rain"
            case .whiteNoise: return "sound_whitenoise"
            case .cafe:       return "sound_cafe"
            case .forest:     return "sound_forest"
            case .ocean:      return "sound_ocean"
            }
        }
    }

    // MARK: - Observable State

    private(set) var currentSound: Sound = .none
    private(set) var isPlaying = false

    var volume: Float = 0.5 {
        didSet { player?.volume = volume }
    }

    // MARK: - Private

    private var player: AVAudioPlayer?

    // MARK: - Public Interface

    func play(_ sound: Sound) {
        guard sound != .none else {
            stop()
            return
        }

        // Already playing this exact sound — nothing to do
        if sound == currentSound && isPlaying { return }

        guard let filename = sound.filename,
              let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
            // File not in bundle yet — update selection but don't crash
            print("[Audio] Missing file: \(sound.filename ?? "nil").mp3")
            currentSound = sound
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: .mixWithOthers  // won't silence podcasts/music
            )
            try AVAudioSession.sharedInstance().setActive(true)

            player?.stop()
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1   // loop indefinitely
            player?.volume = volume
            player?.prepareToPlay()
            player?.play()

            currentSound = sound
            isPlaying = true
        } catch {
            print("[Audio] Playback error: \(error)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
        currentSound = .none
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }

    /// Pause without clearing the selected sound (used when app backgrounds)
    func pausePlayback() {
        player?.pause()
        isPlaying = false
    }

    /// Resume the previously selected sound
    func resumePlayback() {
        guard currentSound != .none else { return }
        player?.play()
        isPlaying = true
    }
}
