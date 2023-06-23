//
//  PsalterAppDelegate.m
//  PsalmsForWorship
//
//  Created by PHILIP LODEN on 4/18/11.
//  Copyright 2011 Deo Volente, LLC. All rights reserved.
//

import AVKit
import SwiftTheme

let kFavoritesDictionaryName = "favorites"
let kFavoriteSongNumbersDictionaryName = "favoriteSongNumbers"
let kSearchPsalmsShortcutIdentifier = "com.deovolentellc.PsalmsForWorship.searchPsalms"
let kFavoritePsalmShortcutIdentifier = "com.deovolentellc.PsalmsForWorship.openFavoritePsalm"
let PFWFavoritesShortcutPsalmIdentifierKey = "songNumber"

// MARK: -
// MARK: Application lifecycle

//@UIApplicationMain
open class SFWAppDelegate: UIResponder, SongDetailVCDelegate, UIApplicationDelegate {
    private var songsManager: SongsManager?
    private var favoritesSynchronizer = FavoritesSyncronizer()
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

    open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        do {
            try favoritesSynchronizer.synciCloud()
        } catch {
            print("UIApplication: didFinishLaunchingWithOptions: synciCloud failed")
        }

        songsManager = SongsManager(appConfig: appConfig)
        songsManager?.loadSongs()
        
        if
            let defaultCollection = songsManager?.songCollections.first,
            let defaultSong = defaultCollection.songs?.first
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
        
        Settings.addObserver(forSettings: self)
        
        window = UIWindow()
        window?.rootViewController = mainController
        changeThemeAsNeeded()
        applyStyling()
        window?.makeKeyAndVisible()
        
        return true
    }

    public func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
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

        if (identifier == kSearchPsalmsShortcutIdentifier) {
            navigationController?.popToRootViewController(animated: false)

            let vc = Helper.mainStoryboard_iPhone().instantiateViewController(withIdentifier: "PsalmIndexVC") as? SongIndexVC
            vc?.songsManager = songsManager
            if let vc = vc {
                navigationController?.show(vc, sender: nil)
            }

            handeled = true
        } else if (identifier == kFavoritePsalmShortcutIdentifier) {
            let songNumber = shortcutItem?.userInfo?[PFWFavoritesShortcutPsalmIdentifierKey] as? String
            
            if
                let songsManager = songsManager,
                let song = songsManager.songForNumber(songNumber)
            {
                songsManager.setcurrentSong(song, songsToDisplay: IndexVC.favoriteSongs(songsManager: songsManager))
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
            appearance.titleTextAttributes = [.foregroundColor: UIColor(named: "NavBarBackground")!.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(named: "NavBarBackground")!.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))]
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
        
        UINavigationBar.appearance().theme_standardAppearance = ThemeNavigationBarAppearancePicker(appearances: defaultLightNavBarAppearance, whiteNavBarAppearance, darkNavBarAppearance)
        UINavigationBar.appearance().theme_scrollEdgeAppearance = ThemeNavigationBarAppearancePicker(appearances: defaultLightNavBarAppearance, whiteNavBarAppearance, darkNavBarAppearance)
        
        UINavigationBar.appearance().theme_tintColor = ThemeColors(
            defaultLight: .white,
            white: UIColor(named: "NavBarBackground")!.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)),
            night: .white
        ).toHex()
        
        UISearchBar.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).theme_barStyle = ThemeBarStylePicker(arrayLiteral: .black, .default, .default)
        
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
