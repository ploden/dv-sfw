//
//  PsalterAppDelegate.m
//  PsalmsForWorship
//
//  Created by PHILIP LODEN on 4/18/11.
//  Copyright 2011 Deo Volente, LLC. All rights reserved.
//

import AVKit
import SwiftTheme
import StoreKit

enum ShortcutIdentifier: String {
    case goTofavoriteSong
}

// MARK: -
// MARK: Application lifecycle

open class SFWAppDelegate: UIResponder, SongDetailVCDelegate, UIApplicationDelegate {
    let imageCacheManager = ImageCacheManager()
    private var songsManager: SongsManager?
    lazy public var appConfig: AppConfig = {
        let targetName = Bundle.main.infoDictionary?["CFBundleName"] as! String
        let dirName = targetName.lowercased() + "-resources"
        
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "AppConfig", ofType: "plist", inDirectory: dirName) ?? "")
        
        var result: AppConfig?
        
        do {
            let data = try Data.init(contentsOf: url, options: .mappedIfSafe)
            let decoder = PropertyListDecoder()
            result = try decoder.decode(AppConfig.self, from: data)
        } catch {
            print("There was an error reading app config! \(error)")
        }
        
        let soundFonts: [SoundFont]? = result?.soundFonts.compactMap {
            return SoundFont(filename: $0.filename, fileExtension: $0.filetype, isDefault: $0.isDefault, title: $0.title)
        }
        
        let settings = Settings(fromUserDefaults: .standard) ?? Settings()            
        _ = settings.new(withSoundFonts: soundFonts ?? []).save(toUserDefaults: .standard)
        
        return result!
    }()
    public var window: UIWindow?
    weak var navigationController: UINavigationController?

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let syncInstance = FavoritesSyncronizer.shared
        try? syncInstance.synciCloud()

        songsManager = SongsManager(appConfig: appConfig)
        songsManager?.loadSongs()
        
        if
            let defaultCollection = songsManager?.songCollections.first,
            let defaultSong = defaultCollection.songs?.first
        {
            songsManager?.setcurrentSong(defaultSong, songsToDisplay: defaultCollection.songs)
        }
        
        updateFavoritesShortcuts()

        applyStyling()
        
        startAnalytics()
        
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
                    index.title = ""
                    
                    if let songIndexVC = SongIndexVC.pfw_instantiateFromStoryboard() as? SongIndexVC {
                        songIndexVC.songsManager = songsManager
                        songIndexVC.title = ""
                        index.navigationController?.setToolbarHidden(false, animated: false)
                        index.navigationController?.pushViewController(songIndexVC, animated: false)
                    }
                    
                    detail.navigationItem.leftItemsSupplementBackButton = true
                    detail.songsManager = songsManager
                    detail.delegate = self
                }
                mainController = split
            }
        } else if
            let nav = Helper.mainStoryboard_iPhone().instantiateInitialViewController() as? UINavigationController,
            let index = nav.topViewController as? IndexVC
        {
            navigationController = nav
            index.title = ""
            index.songsManager = songsManager
            index.sections = appConfig.index
            mainController = navigationController
            
            if let songIndexVC = SongIndexVC.pfw_instantiateFromStoryboard() as? SongIndexVC {
                songIndexVC.songsManager = songsManager
                navigationController?.setToolbarHidden(false, animated: false)
                navigationController?.pushViewController(songIndexVC, animated: false)
            }
        }
        
        window = UIWindow()
        window?.rootViewController = mainController
        window?.makeKeyAndVisible()
        
        return true
    }

    public func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }

    public func applicationWillEnterForeground(_ application: UIApplication) {
        let syncInstance = FavoritesSyncronizer.shared
        try? syncInstance.synciCloud()
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        changeThemeAsNeeded()
    }

    func handle(_ shortcutItem: UIApplicationShortcutItem?) -> Bool {
        var handeled = false

        if
            let identifier = shortcutItem?.type,
            let shortcut = ShortcutIdentifier(rawValue: identifier)
        {
            switch shortcut {
            case .goTofavoriteSong:
                handeled = true
                break
            default:
                break
            }
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
            let songs = songsManager.currentSong?.collection.songs
        {
            UIApplication.shared.shortcutItems = FavoritesSyncronizer.favoriteShortcutItems(songs, songsManager: songsManager)
        }
    }
    
    func songsToDisplayForDetailVC(_ detailVC: SongDetailVC?) -> [Song]? {
        return songsManager?.currentSong?.collection.songs
    }
    
    func isSearchingForDetailVC(_ detailVC: SongDetailVC?) -> Bool {
        return false
    }
    
    func applyStyling() {
        UINavigationBar.appearance().theme_titleTextAttributes = ThemeStringAttributesPicker(
            [.foregroundColor: UIColor.white],
            [.foregroundColor: UIColor(named: "NavBarBackground")!],
            [.foregroundColor: UIColor.white]
        )
        
        //Set navigation bar Back button tint colour
        UINavigationBar.appearance().theme_tintColor = ThemeColors(
            defaultLight: .white,
            white: UIColor(named: "NavBarBackground")!,
            night: .white
        ).toHex()

        // Set status bar style by setting nav bar style
        //UINavigationBar.appearance().theme_barStyle = ThemeBarStyles(defaultLight: .black, white: .default, night: .black).toHex()
        
        let settings = Settings(fromUserDefaults: .standard) ?? Settings()
        _ = settings.save(toUserDefaults: .standard)
        Settings.addObserver(forSettings: self)
        
        UINavigationBar.appearance().theme_barTintColor = ThemeColors(
            defaultLight: UIColor(named: "NavBarBackground")!,
            white: .systemBackground,
            night: UIColor.systemBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        ).toHex()
        
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIToolbar.self]).theme_tintColor = ThemeColors(
            defaultLight: UIView().tintColor!,
            white: UIColor(named: "NavBarBackground")!,
            night: .white
        ).toHex()

        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).theme_tintColor = ThemeColors(
            defaultLight: UIView().tintColor!,
            white: UIColor(named: "NavBarBackground")!,
            night: .white
        ).toHex()
    }
    
    func changeThemeAsNeeded() {
        if
            let settings = Settings(fromUserDefaults: .standard),
            let window = window
        {
            let theme = settings.calculateTheme(forUserInterfaceStyle: UIScreen.main.traitCollection.userInterfaceStyle)
            
            if theme.rawValue != ThemeManager.currentThemeIndex {
                if theme == .defaultLight || theme == .white {
                    window.overrideUserInterfaceStyle = .light
                    ThemeManager.setTheme(index: theme.rawValue)
                    if theme != settings.theme {
                        _ = settings.new(withTheme: theme, userInterfaceStyle: UIScreen.main.traitCollection.userInterfaceStyle).save(toUserDefaults: .standard)
                    }
                } else if theme == .night {
                    window.overrideUserInterfaceStyle = .dark
                    ThemeManager.setTheme(index: theme.rawValue)
                    if theme != settings.theme {
                        _ = settings.new(withTheme: theme, userInterfaceStyle: UIScreen.main.traitCollection.userInterfaceStyle).save(toUserDefaults: .standard)
                    }
                }
            }
        }
    }
    
    open func startAnalytics() {}
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
