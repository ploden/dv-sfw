//
//  PsalterAppDelegate.m
//  SongsForWorship
//
//  Created by Phil Loden on 4/18/11. Licensed under the MIT license, as follows:
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

import AVKit
import SwiftTheme
import UIKit

let kFavoritesDictionaryName = "favorites"
let kFavoriteSongNumbersDictionaryName = "favoriteSongNumbers"
let kSearchPsalmsShortcutIdentifier = "com.deovolentellc.SongsForWorship.searchPsalms"
let kFavoritePsalmShortcutIdentifier = "com.deovolentellc.SongsForWorship.openFavoritePsalm"
let PFWFavoritesShortcutPsalmIdentifierKey = "songNumber"

// MARK: -
// MARK: Application lifecycle

open class SFWAppDelegate: UIResponder, SongDetailVCDelegate, UIApplicationDelegate {
    let imageCacheManager = ImageCacheManager()
    private var songsManager: SongsManager!
    private var favoritesSynchronizer = FavoritesSyncronizer()
    public var window: UIWindow?
    weak var navigationController: UINavigationController?

    open func application(_ application: UIApplication,
                          didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool
    {
        let appConfig = Self.readAppConfig()

        guard let settings = Settings(fromUserDefaults: .standard) else {
            fatalError("There was an error reading settings!")
        }

        do {
            try favoritesSynchronizer.synciCloud()
        } catch {
            print("UIApplication: didFinishLaunchingWithOptions: synciCloud failed")
        }

        songsManager = SongsManager(appConfig: appConfig)

        if
            let defaultCollection = songsManager?.songCollections.first,
            let defaultSong = defaultCollection.songs.first
        {
            songsManager?.setcurrentSong(defaultSong, songsToDisplay: defaultCollection.songs)
        }

        updateFavoritesShortcuts()

        if shouldPerformAnalytics() {
            startAnalytics()
        }

        var mainController: UIViewController?

        if UIDevice.current.userInterfaceIdiom == .pad {
            if let split = Helper.mainStoryboard_iPad().instantiateInitialViewController() as? UISplitViewController {
                split.delegate = self

                if
                    let indexNC = split.viewController(for: .primary) as? UINavigationController,
                    let index = indexNC.topViewController as? IndexVC,
                    let detailNC = split.viewController(for: .secondary) as? UINavigationController,
                    let detail = detailNC.topViewController as? SongDetailVC
                {
                    index.sections = appConfig.index
                    index.songsManager = songsManager
                    index.appConfig = appConfig
                    index.settings = settings
                    index.title = ""

                    if let songIndexVC = SongIndexVC.instantiateFromStoryboard(appConfig: appConfig, settings: settings, songsManager: songsManager) as? SongIndexVC {
                        songIndexVC.title = ""
                        index.navigationController?.setToolbarHidden(false, animated: false)
                        index.navigationController?.pushViewController(songIndexVC, animated: false)
                    }

                    detail.navigationItem.leftItemsSupplementBackButton = true
                    detail.songsManager = songsManager
                    detail.appConfig = appConfig
                    detail.settings = settings
                    detail.delegate = self
                }
                mainController = split
            }
        } else if
            let nav = Helper.mainStoryboardForiPhone().instantiateInitialViewController() as? UINavigationController,
            let index = nav.topViewController as? IndexVC
        {
            navigationController = nav
            index.title = ""
            index.songsManager = songsManager
            index.appConfig = appConfig
            index.settings = settings
            index.sections = appConfig.index
            mainController = navigationController

            if let songIndexVC = SongIndexVC.instantiateFromStoryboard(appConfig: appConfig, settings: settings, songsManager: songsManager) as? SongIndexVC {
                navigationController?.setToolbarHidden(false, animated: false)
                navigationController?.pushViewController(songIndexVC, animated: false)
            }
        }

        Settings.addObserver(forSettings: self)

        window = UIWindow()
        window?.rootViewController = mainController
        changeThemeAsNeeded()
        applyStyling()
        window?.makeKeyAndVisible()
        
        return true
    }

    public func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }

    public func applicationWillEnterForeground(_ application: UIApplication) {
        do {
            try favoritesSynchronizer.synciCloud()
        } catch {
            print("UIApplication: applicationWillEnterForeground: synciCloud failed")
        }
    }

    public func applicationWillResignActive(_ application: UIApplication) {
        do {
            try favoritesSynchronizer.synciCloud()
        } catch {
            print("UIApplication: applicationWillResignActive: synciCloud failed")
        }
    }

    public func applicationDidBecomeActive(_ application: UIApplication) {
        changeThemeAsNeeded()
    }

    func handle(_ shortcutItem: UIApplicationShortcutItem?) -> Bool {
        let identifier = shortcutItem?.type

        var handeled = false

        if identifier == kSearchPsalmsShortcutIdentifier {
            navigationController?.popToRootViewController(animated: false)

            let viewController = Helper.mainStoryboardForiPhone().instantiateViewController(withIdentifier: "PsalmIndexVC") as? SongIndexVC
            viewController?.songsManager = songsManager
            if let viewController = viewController {
                navigationController?.show(viewController, sender: nil)
            }

            handeled = true
        } else if identifier == kFavoritePsalmShortcutIdentifier {
            let songNumber = shortcutItem?.userInfo?[PFWFavoritesShortcutPsalmIdentifierKey] as? String

            if
                let songsManager = songsManager,
                let song = songsManager.songForNumber(songNumber)
            {
                songsManager.setcurrentSong(song, songsToDisplay: FavoritesVC.favoriteSongs(songsManager: songsManager))
            }

            handeled = true
        }

        return handeled
    }

    public func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {

        let handeled = handle(shortcutItem)
        completionHandler(handeled)
    }

    public func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    @objc func favoritesChanged(_ notification: Notification?) {
        updateFavoritesShortcuts()
    }

    func updateFavoritesShortcuts() {
        if
            let songsManager = songsManager,
            let currentSong = songsManager.currentSong,
            let songs = songsManager.collection(forSong: currentSong)?.songs as? [Song]
        {
            UIApplication.shared.shortcutItems = FavoritesSyncronizer.favoriteShortcutItems(songs, songsManager: songsManager)
        }
    }

    func songsToDisplayForDetailVC(_ detailVC: SongDetailVC?) -> [Song]? {
        guard
            let songsManager = songsManager,
            let currentSong = songsManager.currentSong
        else
        {
            return nil
        }
        return songsManager.collection(forSong: currentSong)?.songs
    }

    func isSearchingForDetailVC(_ detailVC: SongDetailVC?) -> Bool {
        return false
    }

    func applyStyling() {
        let defaultLightNavBarAppearance: UINavigationBarAppearance = {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.backgroundColor = UIColor(named: "NavBarBackground")!.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            return appearance
        }()

        let whiteNavBarAppearance: UINavigationBarAppearance = {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.titleTextAttributes = [
                .foregroundColor: UIColor(named: "NavBarBackground")!.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            ]
            appearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor(named: "NavBarBackground")!.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            ]
            appearance.backgroundColor = UIColor.systemBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            return appearance
        }()

        let darkNavBarAppearance: UINavigationBarAppearance = {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.backgroundColor = UIColor.systemBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
            return appearance
        }()

        UINavigationBar.appearance().theme_standardAppearance = ThemeNavigationBarAppearancePicker(
            appearances: defaultLightNavBarAppearance, whiteNavBarAppearance, darkNavBarAppearance
        )
        UINavigationBar.appearance().theme_scrollEdgeAppearance = ThemeNavigationBarAppearancePicker(
            appearances: defaultLightNavBarAppearance, whiteNavBarAppearance, darkNavBarAppearance
        )

        UINavigationBar.appearance().theme_tintColor = ThemeColors(
            defaultLight: .white,
            white: UIColor(named: "NavBarBackground")!.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)),
            night: .white
        ).toHex()

        UISearchBar.appearance(
            whenContainedInInstancesOf: [UINavigationBar.self]).theme_barStyle = ThemeBarStylePicker(arrayLiteral: .black, .default, .default
            )

        UISearchBar.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).theme_barTintColor = ThemeColors(
            defaultLight: .white,
            white: UIColor(named: "NavBarBackground")!.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)),
            night: .white
        ).toHex()

        UISearchBar.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).theme_tintColor = ThemeColors(
            defaultLight: .white,
            white: UIColor(named: "NavBarBackground")!.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)),
            night: .white
        ).toHex()

        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIToolbar.self]).theme_tintColor = ThemeColors(
            defaultLight: UIView().tintColor!,
            white: UIColor(named: "NavBarBackground")!.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)),
            night: .white
        ).toHex()

        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).theme_tintColor = ThemeColors(
            defaultLight: UIView().tintColor!,
            white: UIColor(named: "NavBarBackground")!.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)),
            night: .white
        ).toHex()

        UIToolbar.appearance().theme_barStyle = ThemeBarStyles(
            defaultLight: .default,
            white: .default,
            night: .black
        ).toHex()

        UIToolbar.appearance().theme_backgroundColor = ThemeColors(
            defaultLight: UIColor.systemBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)),
            white: UIColor.systemBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)),
            night: UIColor.systemBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        ).toHex()
    }

    func changeThemeAsNeeded() {
        if
            let settings = Settings(fromUserDefaults: .standard),
            let window = window
        {
            let theme = settings.calculateTheme(forUserInterfaceStyle: UIScreen.main.traitCollection.userInterfaceStyle)

            if
                let currentTheme = ThemeSetting(rawValue: ThemeManager.currentThemeIndex),
                theme != currentTheme
            {
                ThemeManager.setTheme(index: theme.rawValue)

                if theme == .defaultLight || theme == .white {
                    window.overrideUserInterfaceStyle = .light
                } else if theme == .night {
                    window.overrideUserInterfaceStyle = .dark
                }

                if theme != settings.theme {
                    _ = settings.new(withTheme: theme, userInterfaceStyle: UIScreen.main.traitCollection.userInterfaceStyle).save(toUserDefaults: .standard)
                }

                NotificationCenter.default.post(name: Notification.Name.themeDidChange, object: nil)
            }
        }
    }

    open func startAnalytics() {}

    open func shouldPerformAnalytics() -> Bool {
        return false
    }

    public static func readAppConfig() -> AppConfig {
        guard let targetName = Bundle.main.infoDictionary?["CFBundleName"] as? String else {
            fatalError("Could not access CFBundleName")
        }

        let dirName = targetName.lowercased() + "-resources"

        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "AppConfig", ofType: "plist", inDirectory: dirName) ?? "")

        var result: AppConfig?

        do {
            let data = try Data.init(contentsOf: url, options: .mappedIfSafe)
            let decoder = PropertyListDecoder()
            result = try decoder.decode(AppConfig.self, from: data)
        } catch {
            fatalError("There was an error reading app config! \(error)")
        }

        let soundFonts: [SoundFont]? = result?.soundFonts.compactMap {
            return SoundFont(filename: $0.filename, fileExtension: $0.filetype, isDefault: $0.isDefault, title: $0.title)
        }

        let settings = Settings(fromUserDefaults: .standard) ?? Settings()
        _ = settings.new(withSoundFonts: soundFonts ?? []).save(toUserDefaults: .standard)

        return result!
    }
}

extension SFWAppDelegate: SettingsObserver {
    func settingsDidChange(_ notification: Notification) {
        changeThemeAsNeeded()
    }
}

extension SFWAppDelegate: UISplitViewControllerDelegate {
    public func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) {
        svc.presentsWithGesture = displayMode != .oneBesideSecondary
    }
}
