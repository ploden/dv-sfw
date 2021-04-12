//
//  Settings.swift
//  SongsForWorship
//
//  Created by Philip Loden on 9/17/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit
import SwiftTheme

struct ThemeColors {
    var defaultLight: UIColor
    var white: UIColor
    var night: UIColor
    
    func toHex() -> ThemeColorPicker {
        return [defaultLight.hexString(false), white.hexString(false), night.hexString(false)]
    }
}

enum FontSizeSetting: Int, CaseIterable, Codable {
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

enum ThemeSetting: Int, CaseIterable, Codable {
    case defaultLight = 0
    case white = 1
    case night = 2
}

@objc protocol SettingsObserver {
    @objc func settingsDidChange(_ notification: Notification)
}

public struct Settings: Codable {
    public var shouldUseSystemFonts = false
    public var autoNightTheme = true
    private(set) var soundFonts: [SoundFont] = [SoundFont]()
    private(set) var selectedSoundFont: SoundFont?
    private(set)  var fontSizeSetting: FontSizeSetting = .medium
    var fontSize: CGFloat {
        get {
            return CGFloat(fontSizeSetting.rawValue) / 10.0
        }
    }
    private(set) var theme: ThemeSetting = .defaultLight
    private(set) var shouldShowSheetMusicInPortrait_iPhone: Bool = false
    private(set) var shouldShowSheetMusicInLandscape_iPhone: Bool = true
    private(set) var shouldShowSheetMusic_iPad: Bool = true

    func calculateTheme(forUserInterfaceStyle style: UIUserInterfaceStyle) -> ThemeSetting {
        if autoNightTheme {
            if style == .dark {
                return .night
            } else if theme != .night {
                return theme
            }
            return .defaultLight
        }
        return theme
    }
    
    func new(withAutoNightTheme autoNightTheme: Bool, userInterfaceStyle: UIUserInterfaceStyle) -> Settings {
        let s = Settings(
            shouldUseSystemFonts: self.shouldUseSystemFonts,
            autoNightTheme: autoNightTheme,
            soundFonts: self.soundFonts,
            selectedSoundFont: self.selectedSoundFont,
            fontSizeSetting: self.fontSizeSetting,
            theme: self.theme,
            shouldShowSheetMusicInPortrait_iPhone: self.shouldShowSheetMusicInPortrait_iPhone,
            shouldShowSheetMusicInLandscape_iPhone: self.shouldShowSheetMusicInLandscape_iPhone,
            shouldShowSheetMusic_iPad: self.shouldShowSheetMusic_iPad
        )
        
        let newTheme = s.calculateTheme(forUserInterfaceStyle: userInterfaceStyle)

        let s2 = Settings(
            shouldUseSystemFonts: self.shouldUseSystemFonts,
            autoNightTheme: autoNightTheme,
            soundFonts: self.soundFonts,
            selectedSoundFont: self.selectedSoundFont,
            fontSizeSetting: self.fontSizeSetting,
            theme: newTheme,
            shouldShowSheetMusicInPortrait_iPhone: self.shouldShowSheetMusicInPortrait_iPhone,
            shouldShowSheetMusicInLandscape_iPhone: self.shouldShowSheetMusicInLandscape_iPhone,
            shouldShowSheetMusic_iPad: self.shouldShowSheetMusic_iPad
        )
        
        return s2
    }
    
    func new(withShouldShowSheetMusicInPortrait_iPhone shouldShowSheetMusicInPortrait_iPhone: Bool) -> Settings {
        let s = Settings(
            shouldUseSystemFonts: self.shouldUseSystemFonts,
            autoNightTheme: self.autoNightTheme,
            soundFonts: self.soundFonts,
            selectedSoundFont: self.selectedSoundFont,
            fontSizeSetting: self.fontSizeSetting,
            theme: self.theme,
            shouldShowSheetMusicInPortrait_iPhone: shouldShowSheetMusicInPortrait_iPhone,
            shouldShowSheetMusicInLandscape_iPhone: self.shouldShowSheetMusicInLandscape_iPhone,
            shouldShowSheetMusic_iPad: self.shouldShowSheetMusic_iPad
        )
        return s
    }
    
    func new(withShouldShowSheetMusicInLandscape_iPhone shouldShowSheetMusicInLandscape_iPhone: Bool) -> Settings {
        let s = Settings(
            shouldUseSystemFonts: self.shouldUseSystemFonts,
            autoNightTheme: self.autoNightTheme,
            soundFonts: self.soundFonts,
            selectedSoundFont: self.selectedSoundFont,
            fontSizeSetting: self.fontSizeSetting,
            theme: self.theme,
            shouldShowSheetMusicInPortrait_iPhone: self.shouldShowSheetMusicInPortrait_iPhone,
            shouldShowSheetMusicInLandscape_iPhone: shouldShowSheetMusicInLandscape_iPhone,
            shouldShowSheetMusic_iPad: self.shouldShowSheetMusic_iPad
        )
        return s
    }
    
    func new(withShouldShowSheetMusic_iPad shouldShowSheetMusic_iPad: Bool) -> Settings {
        let s = Settings(
            shouldUseSystemFonts: self.shouldUseSystemFonts,
            autoNightTheme: self.autoNightTheme,
            soundFonts: self.soundFonts,
            selectedSoundFont: self.selectedSoundFont,
            fontSizeSetting: self.fontSizeSetting,
            theme: self.theme,
            shouldShowSheetMusicInPortrait_iPhone: self.shouldShowSheetMusicInPortrait_iPhone,
            shouldShowSheetMusicInLandscape_iPhone: self.shouldShowSheetMusicInLandscape_iPhone,
            shouldShowSheetMusic_iPad: shouldShowSheetMusic_iPad
        )
        return s
    }
    
    func new(withTheme theme: ThemeSetting, userInterfaceStyle: UIUserInterfaceStyle) -> Settings {
        let newAutoNightTheme: Bool = {
            if userInterfaceStyle == .dark && theme != .night {
                return false
            } else if userInterfaceStyle == .light && theme == .night {
                return false
            } else {
                return self.autoNightTheme
            }
        }()
        
        let s = Settings(
            shouldUseSystemFonts: self.shouldUseSystemFonts,
            autoNightTheme: newAutoNightTheme,
            soundFonts: self.soundFonts,
            selectedSoundFont: self.selectedSoundFont,
            fontSizeSetting: self.fontSizeSetting,
            theme: theme,
            shouldShowSheetMusicInPortrait_iPhone: self.shouldShowSheetMusicInPortrait_iPhone,
            shouldShowSheetMusicInLandscape_iPhone: self.shouldShowSheetMusicInLandscape_iPhone,
            shouldShowSheetMusic_iPad: self.shouldShowSheetMusic_iPad
        )
        return s
    }
    
    func new(withShouldUseSystemFonts shouldUseSystemFonts: Bool) -> Settings {
        let s = Settings(
            shouldUseSystemFonts: shouldUseSystemFonts,
            autoNightTheme: self.autoNightTheme,
            soundFonts: self.soundFonts,
            selectedSoundFont: self.selectedSoundFont,
            fontSizeSetting: self.fontSizeSetting,
            theme: self.theme,
            shouldShowSheetMusicInPortrait_iPhone: self.shouldShowSheetMusicInPortrait_iPhone,
            shouldShowSheetMusicInLandscape_iPhone: self.shouldShowSheetMusicInLandscape_iPhone,
            shouldShowSheetMusic_iPad: self.shouldShowSheetMusic_iPad
        )
        return s
    }

    func new(withSoundFonts soundFonts: [SoundFont]) -> Settings {
        let s = Settings(
            shouldUseSystemFonts: self.shouldUseSystemFonts,
            autoNightTheme: self.autoNightTheme,
            soundFonts: soundFonts,
            selectedSoundFont: self.selectedSoundFont,
            fontSizeSetting: self.fontSizeSetting,
            theme: self.theme,
            shouldShowSheetMusicInPortrait_iPhone: self.shouldShowSheetMusicInPortrait_iPhone,
            shouldShowSheetMusicInLandscape_iPhone: self.shouldShowSheetMusicInLandscape_iPhone,
            shouldShowSheetMusic_iPad: self.shouldShowSheetMusic_iPad
        )
        return s
    }
    
    func save(toUserDefaults userDefaults: UserDefaults) -> Settings? {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self) {
            userDefaults.set(encoded, forKey: "SFWSettings")
            OperationQueue.main.addOperation({
                NotificationCenter.default.post(name: Notification.Name.settingsDidChange, object: nil)
            })
            return self
        }
        return nil
    }
    
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
    
    func newWithIncreasedFontSize() -> Settings {
        if let larger = fontSizeSetting.largerFontSizeSetting() {
            let s = Settings(
                shouldUseSystemFonts: self.shouldUseSystemFonts,
                autoNightTheme: self.autoNightTheme,
                soundFonts: self.soundFonts,
                selectedSoundFont: self.selectedSoundFont,
                fontSizeSetting: larger,
                theme: self.theme,
                shouldShowSheetMusicInPortrait_iPhone: self.shouldShowSheetMusicInPortrait_iPhone,
                shouldShowSheetMusicInLandscape_iPhone: self.shouldShowSheetMusicInLandscape_iPhone,
                shouldShowSheetMusic_iPad: self.shouldShowSheetMusic_iPad
            )
            return s
        }
        return self
    }
    
    func newWithDecreasedFontSize() -> Settings {
        if let smaller = fontSizeSetting.smallerFontSizeSetting() {
            let s = Settings(
                shouldUseSystemFonts: self.shouldUseSystemFonts,
                autoNightTheme: self.autoNightTheme,
                soundFonts: self.soundFonts,
                selectedSoundFont: self.selectedSoundFont,
                fontSizeSetting: smaller,
                theme: self.theme,
                shouldShowSheetMusicInPortrait_iPhone: self.shouldShowSheetMusicInPortrait_iPhone,
                shouldShowSheetMusicInLandscape_iPhone: self.shouldShowSheetMusicInLandscape_iPhone,
                shouldShowSheetMusic_iPad: self.shouldShowSheetMusic_iPad
            )
            return s
        }
        return self
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
    
    static func addObserver(forSettings anObserver: SettingsObserver) {
        NotificationCenter.default.addObserver(anObserver as Any, selector: #selector(SettingsObserver.settingsDidChange(_:)), name: Notification.Name.settingsDidChange, object: nil)
    }

    func removeObserver(forSettings anObserver: SettingsObserver?) {
        NotificationCenter.default.removeObserver(anObserver as Any, name: .settingsDidChange, object: nil)
    }
}
 
extension Settings {
    public init?(fromUserDefaults userDefaults: UserDefaults) {
        if let savedSettings = userDefaults.object(forKey: "SFWSettings") as? Data {
            let decoder = JSONDecoder()
            if let loadedSettings = try? decoder.decode(Settings.self, from: savedSettings) {
                self = loadedSettings
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
