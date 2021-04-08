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

@UIApplicationMain
open class PsalterAppDelegate: UIResponder, SongDetailVCDelegate, UIApplicationDelegate {
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
        
        return result!
    }()
    public var window: UIWindow?
    public var settings: Settings = Settings() {
        didSet {
            let soundFonts: [SoundFont] = appConfig.soundFonts.compactMap {
                return SoundFont(filename: $0.filename, fileExtension: $0.filetype, isDefault: $0.isDefault, title: $0.title)                    
            }
            settings.soundFonts = soundFonts
        }
    }
    weak var navigationController: UINavigationController?

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let syncInstance = FavoritesSyncronizer.shared
        syncInstance.synciCloud()
        NotificationCenter.default.addObserver(self, selector: #selector(favoritesChanged(_:)), name: NSNotification.Name.favoritesDidChange, object: nil)

        songsManager = SongsManager(appConfig: appConfig)
        songsManager?.loadSongs()
        
        if
            let defaultCollection = songsManager?.songCollections.first,
            let defaultSong = defaultCollection.songs?.first
        {
            songsManager?.setcurrentSong(defaultSong, songsToDisplay: defaultCollection.songs)
        }
        
        updateFavoritesShortcuts()

        //ThemeManager.setTheme(index: 1)
        
        /*
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.theme_backgroundColor = ThemeColors(light: UIColor(named: "NavBarBackground")!, dark: .black, white: .white).toHex()
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        let buttonAppearance = UIBarButtonItemAppearance(style: .plain)
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.buttonAppearance = buttonAppearance
        navBarAppearance.backButtonAppearance = buttonAppearance
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance

        UINavigationBar.appearance(whenContainedInInstancesOf: [UINavigationController.self]).standardAppearance = navBarAppearance
        UINavigationBar.appearance(whenContainedInInstancesOf: [UINavigationController.self]).scrollEdgeAppearance = navBarAppearance
        //UINavigationBar.appearance().tintColor = .white
 */
        
        // Set navigation bar tint / background colour
        //UINavigationBar.appearance().barTintColor = UIColor.red
        
        // Set Navigation bar Title colour
        //UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().theme_titleTextAttributes = ThemeStringAttributesPicker([.foregroundColor: UIColor.white], [.foregroundColor: UIColor(named: "NavBarBackground")!])
        
        // Set navigation bar ItemButton tint colour, including back chevron
        //UIBarButtonItem.appearance().tintColor = UIColor.white

        // Set Navigation bar background image
        //let navBgImage:UIImage = UIImage(named: "bg_blog_navbar_reduced.jpg")!
        // Set navigation bar tint / background colour
        //UINavigationBar.appearance().barTintColor = UIColor(named: "NavBarBackground")
        
        
        //Set navigation bar Back button tint colour
        UINavigationBar.appearance().theme_tintColor = ThemeColors(
            defaultLight: .white,
            white: UIColor(named: "NavBarBackground")!,
            night: .white
        ).toHex()
        
        ThemeManager.setTheme(index: settings.theme.rawValue)
        
        window = UIWindow()
        
        
        UINavigationBar.appearance().theme_barTintColor = ThemeColors(defaultLight: UIColor(named: "NavBarBackground")!, white: .systemBackground, night: UIColor.systemBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))).toHex()
        
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIToolbar.self]).theme_tintColor = ThemeColors(
            defaultLight: UIView().tintColor!,
            white: UIColor(named: "NavBarBackground")!,
            night: .white
        ).toHex()
        
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = nil
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = nil
        
        
        var mainController: UIViewController?

        if UIDevice.current.userInterfaceIdiom == .pad {
            let split = Helper.mainStoryboard_iPad().instantiateInitialViewController() as? UISplitViewController
            let nav = split?.viewControllers[0] as? UINavigationController
            
            if let split = split {
                for vc in split.viewControllers {
                    if
                        let nc = vc as? UINavigationController,
                        let detail = nc.topViewController as? SongDetailVC
                    {
                        detail.navigationItem.leftItemsSupplementBackButton = true
                        detail.navigationItem.leftBarButtonItem = split.displayModeButtonItem
                        detail.songsManager = songsManager
                        detail.delegate = self
                    }
                    if
                        let nc = vc as? UINavigationController,
                        let detail = nc.topViewController as? SongDetailVC
                    {
                        detail.navigationItem.leftItemsSupplementBackButton = true
                        detail.navigationItem.leftBarButtonItem = split.displayModeButtonItem
                        detail.songsManager = songsManager
                        detail.settings = settings
                    }
                }
            }

            let index = Helper.mainStoryboard_iPhone().instantiateViewController(withIdentifier: "IndexVC") as? IndexVC
            index?.sections = appConfig.index
            index?.songsManager = songsManager

            nav?.viewControllers = [index].compactMap { $0 }
            mainController = split
        } else {            
            UITabBar.appearance().tintColor = UIColor.white

            let sb = Helper.mainStoryboard_iPhone()
            
            if let nv = sb.instantiateInitialViewController() as? UINavigationController {
                navigationController = nv
                let index = navigationController?.viewControllers[0] as? IndexVC
                index?.songsManager = songsManager
                index?.sections = appConfig.index
                mainController = navigationController
            }
        }
        
        window?.rootViewController = mainController
        window?.makeKeyAndVisible()
        settings = Settings()
        
        return true
    }

    public func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }

    public func applicationWillEnterForeground(_ application: UIApplication) {
        let syncInstance = FavoritesSyncronizer.shared
        syncInstance.synciCloud()
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
}
