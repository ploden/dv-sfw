//
//  Settings.swift
//  SongsForWorship
//
//  Created by Philip Loden on 9/17/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation

open class Settings {
    var shouldUseSystemFonts = false
    var soundFonts: [SoundFont] = [SoundFont]()
    var selectedSoundFont: SoundFont?
    
    func selectedSoundFontOrDefault() -> SoundFont {
        let font: SoundFont = {
            if let selected = selectedSoundFont {
                return selected
            } else if
                let defaultFont = self.soundFonts.first(where: { $0.isDefault == true })
            {
                return defaultFont
            } else {
                return self.soundFonts.first!
            }
        }()
        
        return font
    }
}
