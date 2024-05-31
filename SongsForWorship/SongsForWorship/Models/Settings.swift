//
//  Settings.swift
//  SongsForWorship
//
//  Created by Phil Loden on 9/17/20. Licensed under the MIT license, as follows:
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
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
    public var fontSize: CGFloat {
        return CGFloat(fontSizeSetting.rawValue) / 10.0
    }
    private(set) var theme: ThemeSetting = .defaultLight
    private(set) var shouldShowSheetMusicInPortraitForiPhone: Bool = false
    private(set) var shouldShowSheetMusicInLandscapeForiPhone: Bool = true
    private(set) var shouldShowSheetMusicForiPad: Bool = true
    public private(set) var loggedTunePurges: [VersionTimestamp] = [VersionTimestamp]()

    func calculateTheme(forUserInterfaceStyle style: UIUserInterfaceStyle) -> ThemeSetting {
        VersionTimestamp(version: "", timestamp: 0)
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
                return true
            }
        }

        return false
    }

    public func new(withAutoNightTheme autoNightTheme: Bool, userInterfaceStyle: UIUserInterfaceStyle) -> Settings {
        var firstNewSettings = self
        firstNewSettings.autoNightTheme = autoNightTheme

        let newTheme = firstNewSettings.calculateTheme(forUserInterfaceStyle: userInterfaceStyle)

        var secondNewSettings = self
        secondNewSettings.autoNightTheme = autoNightTheme
        secondNewSettings.theme = newTheme

        return secondNewSettings
    }

    public func new(withShouldShowSheetMusicInPortraitForiPhone shouldShowSheetMusicInPortraitForiPhone: Bool) -> Settings {
        var newSettings = self
        newSettings.shouldShowSheetMusicInPortraitForiPhone = shouldShowSheetMusicInPortraitForiPhone
        return newSettings
    }

    public func new(withShouldShowSheetMusicInLandscapeForiPhone shouldShowSheetMusicInLandscapeForiPhone: Bool) -> Settings {
        var newSettings = self
        newSettings.shouldShowSheetMusicInLandscapeForiPhone = shouldShowSheetMusicInLandscapeForiPhone
        return newSettings
    }

    public func new(withShouldShowSheetMusicForiPad shouldShowSheetMusicForiPad: Bool) -> Settings {
        var newSettings = self
        newSettings.shouldShowSheetMusicForiPad = shouldShowSheetMusicForiPad
        return newSettings
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

        var newSettings = self
        newSettings.autoNightTheme = newAutoNightTheme
        newSettings.theme = theme
        return newSettings
    }

    public func new(withShouldUseSystemFonts shouldUseSystemFonts: Bool) -> Settings {
        var newSettings = self
        newSettings.shouldUseSystemFonts = shouldUseSystemFonts
        return newSettings
    }

    public func new(withSoundFonts soundFonts: [SoundFont]) -> Settings {
        var newSettings = self
        newSettings.soundFonts = soundFonts
        return newSettings
    }

    public func new(withLoggedTunePurge version: String, timestamp: TimeInterval) -> Settings {
        var logged = self.loggedTunePurges
        logged.append(VersionTimestamp(version: version, timestamp: timestamp))

        var newSettings = self
        newSettings.loggedTunePurges = logged
        return newSettings
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
            var newSettings = self
            newSettings.fontSizeSetting = larger
            return newSettings
        }
        return self
    }

    func newWithDecreasedFontSize() -> Settings {
        if let smaller = fontSizeSetting.smallerFontSizeSetting() {
            var newSettings = self
            newSettings.fontSizeSetting = smaller
            return newSettings
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
        NotificationCenter.default.addObserver(anObserver as Any,
                                               selector: #selector(SettingsObserver.settingsDidChange(_:)),
                                               name: Notification.Name.settingsDidChange,
                                               object: nil)
    }

    func removeObserver(forSettings anObserver: SettingsObserver?) {
        NotificationCenter.default.removeObserver(anObserver as Any, name: .settingsDidChange, object: nil)
    }

    static func addObserver(forTheme anObserver: ThemeObserver) {
        NotificationCenter.default.addObserver(anObserver as Any,
                                               selector: #selector(ThemeObserver.themeDidChange(_:)),
                                               name: Notification.Name.themeDidChange,
                                               object: nil)
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

extension Settings: Equatable {
    public static func == (lhs: Settings, rhs: Settings) -> Bool {
        return lhs.autoNightTheme == rhs.autoNightTheme &&
        lhs.shouldShowSheetMusicForiPad == rhs.shouldShowSheetMusicForiPad &&
        lhs.shouldShowSheetMusicInLandscapeForiPhone == rhs.shouldShowSheetMusicInLandscapeForiPhone &&
        lhs.shouldUseSystemFonts == rhs.shouldUseSystemFonts &&
        lhs.shouldShowSheetMusicInPortraitForiPhone == rhs.shouldShowSheetMusicInPortraitForiPhone &&
        lhs.fontSize == rhs.fontSize &&
        lhs.fontSizeSetting == lhs.fontSizeSetting &&
        lhs.selectedSoundFont == rhs.selectedSoundFont &&
        lhs.soundFonts == rhs.soundFonts &&
        lhs.theme == rhs.theme
    }
}
