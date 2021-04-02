//
//  Settings.swift
//  SongsForWorship
//
//  Created by Philip Loden on 9/17/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

enum FontSizeSetting: Int, CaseIterable {
    case smallest = 120
    case smaller = 140
    case small = 160
    case medium = 180
    case large = 220
    case larger = 280
    case largest = 330
    
    static func sortedCases() -> [FontSizeSetting] {
        return FontSizeSetting.allCases.sorted { $0.rawValue < $1.rawValue }
    }
    
    func smallerFontSizeSetting() -> FontSizeSetting? {
        let allCases = FontSizeSetting.sortedCases()
        
        if
            let idx = allCases.firstIndex(of: self),
            idx - 1 > 0
        {
            return  allCases[idx - 1]
        }
        return nil
    }
    
    func largerFontSizeSetting() -> FontSizeSetting? {
        let allCases = FontSizeSetting.sortedCases()
        
        if
            let idx = allCases.firstIndex(of: self),
            idx + 1 < allCases.count
        {
            return  allCases[idx + 1]
        }
        return nil
    }
}

enum ThemeSetting: String, CaseIterable {
    case standard = "standard"
    case night = "night"
}

@objc protocol SettingsObserver {
    @objc func settingsDidChange(_ notification: Notification)
}

open class Settings {
    open var shouldUseSystemFonts = false {
        didSet {
            NotificationCenter.default.post(name: .settingsDidChange, object: self)
        }
    }
    open var autoNightTheme = false
    var soundFonts: [SoundFont] = [SoundFont]()
    var selectedSoundFont: SoundFont?
    var fontSizeSetting: FontSizeSetting = .medium {
        didSet {
            print("fontSizeSetting: \(fontSizeSetting)")
            NotificationCenter.default.post(name: .settingsDidChange, object: self)
        }
    }
    var fontSize: CGFloat {
        get {
            return CGFloat(fontSizeSetting.rawValue) / 10.0
        }
    }
    var theme: ThemeSetting = .standard
    
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
    
    func increaseFontSize() {
        if let larger = fontSizeSetting.largerFontSizeSetting() {
            fontSizeSetting = larger
        }
    }
    
    func decreaseFontSize() {
        if let smaller = fontSizeSetting.smallerFontSizeSetting() {
            fontSizeSetting = smaller
        }
    }
    
    func canIncreaseFontSize() -> Bool {
        if fontSizeSetting.largerFontSizeSetting() != nil {
            return true
        } else {
            return false
        }
    }
    
    func canDecreaseFontSize() -> Bool {
        if fontSizeSetting.smallerFontSizeSetting() != nil {
            return true
        } else {
            return false
        }
    }
    
    func addObserver(forSettings anObserver: SettingsObserver?) {
        NotificationCenter.default.addObserver(anObserver as Any, selector: #selector(SettingsObserver.settingsDidChange(_:)), name: .settingsDidChange, object: nil)
    }

    func removeObserver(forSettings anObserver: SettingsObserver?) {
        NotificationCenter.default.removeObserver(anObserver as Any)
    }
}
