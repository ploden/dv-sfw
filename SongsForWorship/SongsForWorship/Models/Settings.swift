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

struct ThemeBarStyles {
    var defaultLight: UIBarStyle
    var white: UIBarStyle
    var night: UIBarStyle
    
    func toHex() -> ThemeBarStylePicker {
        return [defaultLight, white, night]
    }
}

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

public enum ThemeSetting: Int, CaseIterable, Codable {
    case defaultLight = 0
    case white = 1
    case night = 2
}

@objc protocol SettingsObserver {
    @objc func settingsDidChange(_ notification: Notification)
}

@objc protocol ThemeObserver {
    @objc func themeDidChange(_ notification: Notification)
}

public struct VersionTimestamp: Codable {
    public let version: String
    public let timestamp: TimeInterval
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
    private(set) var shouldShowAppleMusic = false
    private(set) var shouldShowMusicLibrary = false
    public private(set) var loggedTunePurges: [VersionTimestamp] = [VersionTimestamp]()
    
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
    
    public func calculateShouldPurgeTunes(versionsToPurgeTunes: [String]) -> Bool {
        if let currentVersion = Bundle.main.version, versionsToPurgeTunes.contains(currentVersion) {
            if loggedTunePurges.contains(where: { $0.version == currentVersion }) == false {
                print("SHOULD PURGE TUNES")
                return true
            }
        }
        
        print("SHOULD NOT PURGE TUNES")
        return false
    }
    
    public func new(withAutoNightTheme autoNightTheme: Bool, userInterfaceStyle: UIUserInterfaceStyle) -> Settings {
        var newWith = self
        newWith.autoNightTheme = autoNightTheme
        let newTheme = newWith.calculateTheme(forUserInterfaceStyle: userInterfaceStyle)
        newWith.theme = newTheme
        return newWith
        /*
        let s = Settings(
            shouldUseSystemFonts: self.shouldUseSystemFonts,
            autoNightTheme: autoNightTheme,
            soundFonts: self.soundFonts,
            selectedSoundFont: self.selectedSoundFont,
            fontSizeSetting: self.fontSizeSetting,
            theme: self.theme,
            shouldShowSheetMusicInPortrait_iPhone: self.shouldShowSheetMusicInPortrait_iPhone,
            shouldShowSheetMusicInLandscape_iPhone: self.shouldShowSheetMusicInLandscape_iPhone,
            shouldShowSheetMusic_iPad: self.shouldShowSheetMusic_iPad,
            loggedTunePurges: self.loggedTunePurges
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
            shouldShowSheetMusic_iPad: self.shouldShowSheetMusic_iPad,
            shouldShowAppleMusic: self.shouldShowAppleMusic,
            shouldShowMusicLibrary: self.shouldShowMusicLibrary,
            loggedTunePurges: self.loggedTunePurges
        )
        
        return s2
         */
    }
    
    public func new(withShouldShowSheetMusicInPortrait_iPhone shouldShowSheetMusicInPortrait_iPhone: Bool) -> Settings {
        var newWith = self
        newWith.shouldShowSheetMusicInPortrait_iPhone = shouldShowSheetMusicInPortrait_iPhone
        return newWith
    }
    
    public func new(withShouldShowSheetMusicInLandscape_iPhone shouldShowSheetMusicInLandscape_iPhone: Bool) -> Settings {
        var newWith = self
        newWith.shouldShowSheetMusicInLandscape_iPhone = shouldShowSheetMusicInLandscape_iPhone
        return newWith
    }
    
    public func new(withShouldShowSheetMusic_iPad shouldShowSheetMusic_iPad: Bool) -> Settings {
        var newWith = self
        newWith.shouldShowSheetMusic_iPad = shouldShowSheetMusic_iPad
        return newWith
    }
    
    public func new(withTheme theme: ThemeSetting, userInterfaceStyle: UIUserInterfaceStyle) -> Settings {
        let newAutoNightTheme: Bool = {
            if userInterfaceStyle == .dark && theme != .night {
                return false
            } else if userInterfaceStyle == .light && theme == .night {
                return false
            } else {
                return self.autoNightTheme
            }
        }()
        
        var newWith = self
        newWith.autoNightTheme = newAutoNightTheme
        newWith.theme = theme
        return newWith
    }
    
    public func new(withShouldUseSystemFonts shouldUseSystemFonts: Bool) -> Settings {
        var newWith = self
        newWith.shouldUseSystemFonts = shouldUseSystemFonts
        return newWith
    }

    public func new(withSoundFonts soundFonts: [SoundFont]) -> Settings {
        var newWith = self
        newWith.soundFonts = soundFonts
        return newWith
    }
    
    func new(withShouldShowAppleMusic shouldShowAppleMusic: Bool) -> Settings {
        var newWith = self
        newWith.shouldShowAppleMusic = shouldShowAppleMusic
        return newWith
    }

    public func new(withLoggedTunePurge version: String, timestamp: TimeInterval) -> Settings {
        var logged = self.loggedTunePurges
        logged.append(VersionTimestamp(version: version, timestamp: timestamp))
        
        var newWith = self
        newWith.loggedTunePurges = logged
        return newWith
    }
    
    func new(withShouldShowMusicLibrary shouldShowMusicLibrary: Bool) -> Settings {
        var newWith = self
        newWith.shouldShowMusicLibrary = shouldShowMusicLibrary
        return newWith
    }
    
    public func save(toUserDefaults userDefaults: UserDefaults) -> Settings? {
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
    
    static func addObserver(forTheme anObserver: ThemeObserver) {
        NotificationCenter.default.addObserver(anObserver as Any, selector: #selector(ThemeObserver.themeDidChange(_:)), name: Notification.Name.themeDidChange, object: nil)
    }

    func removeObserver(forTheme anObserver: ThemeObserver?) {
        NotificationCenter.default.removeObserver(anObserver as Any, name: .themeDidChange, object: nil)
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
