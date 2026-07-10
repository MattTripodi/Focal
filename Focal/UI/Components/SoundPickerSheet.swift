//
//  SoundPickerSheet.swift
//  Focal
//
//  Created by Matthew Tripodi on 7/9/26.
//

import SwiftUI

struct SoundPickerSheet: View {
    let audio: AudioManager
    let isPremium: Bool
    let onUpgradeTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Ambient Sound")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 16)

            ForEach(AudioManager.Sound.allCases) { sound in
                Button {
                    if sound.isPremium && !isPremium {
                        onUpgradeTapped()
                    } else if sound == audio.currentSound {
                        audio.stop()
                    } else {
                        audio.play(sound)
                    }
                } label: {
                    HStack {
                        Image(systemName: sound.systemImage)
                            .frame(width: 28)
                        Text(sound.rawValue)
                        Spacer()
                        if sound.isPremium && !isPremium {
                            ProBadge()
                        }
                        if sound == audio.currentSound {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.primary)
                        }
                    }
                    .foregroundStyle(sound.isPremium && !isPremium ? .secondary : .primary)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
