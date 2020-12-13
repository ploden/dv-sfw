//
//  PsalterAppDelegate.m
//  PsalmsForWorship
//
//  Created by PHILIP LODEN on 4/18/11.
//  Copyright 2011 Deo Volente, LLC. All rights reserved.
//

import AVKit

let kFavoritesDictionaryName = "favorites"
let kSearchPsalmsShortcutIdentifier = "com.deovolentellc.PsalmsForWorship.searchPsalms"
let kFavoritePsalmShortcutIdentifier = "com.deovolentellc.PsalmsForWorship.openFavoritePsalm"
let PFWFavoritesShortcutPsalmIdentifierKey = "songNumber"

// MARK: -
// MARK: Application lifecycle

@UIApplicationMain
open class PsalterAppDelegate: UIResponder, UIApplicationDelegate {
    private var songsManager: SongsManager?
    public var window: UIWindow?
    public var settings: Settings = Settings() {
        didSet {
            if let soundFontDicts = getAppConfig()["Sound fonts"] as? [[String:Any]] {
                let soundFonts: [SoundFont] = soundFontDicts.compactMap {
                    if
                        let filename = $0["filename"] as? String,
                        let fileExtension = $0["filetype"] as? String,
                        let title = $0["Title"] as? String,
                        let isDefault = $0["default"] as? Bool
                    {
                        return SoundFont(filename: filename, fileExtension: fileExtension, isDefault: isDefault, title: title)
                    }
                    return nil
                }
                settings.soundFonts = soundFonts
            }
        }
    }
    weak var navigationController: UINavigationController?

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let syncInstance = FavoritesSyncronizer.shared
        syncInstance.synciCloud()
        NotificationCenter.default.addObserver(self, selector: #selector(favoritesChanged(_:)), name: NSNotification.Name.favoritesDidChange, object: nil)

        songsManager = SongsManager(appConfig: getAppConfig())
        songsManager?.loadSongs()
        updateFavoritesShortcuts()

        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(named: "NavBarBackground")
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance(whenContainedInInstancesOf: [UINavigationController.self]).standardAppearance = navBarAppearance
        UINavigationBar.appearance(whenContainedInInstancesOf: [UINavigationController.self]).scrollEdgeAppearance = navBarAppearance
        
        let buttonAppearance = UIBarButtonItemAppearance(style: .plain)
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.buttonAppearance = buttonAppearance        
        UINavigationBar.appearance().tintColor = .white
        
        window = UIWindow()
        
        var mainController: UIViewController?

        if UIDevice.current.userInterfaceIdiom == .pad {
            let split = Helper.mainStoryboard_iPad().instantiateInitialViewController() as? UISplitViewController
            let nav = split?.viewControllers[0] as? UINavigationController
            
            if let split = split {
                for vc in split.viewControllers {
                    if
                        let nc = vc as? UINavigationController,
                        let detail = nc.topViewController as? DetailVC
                    {
                        detail.navigationItem.leftItemsSupplementBackButton = true
                        detail.navigationItem.leftBarButtonItem = split.displayModeButtonItem
                        detail.songsManager = songsManager
                    }
                }
            }

            let index = Helper.mainStoryboard_iPhone().instantiateViewController(withIdentifier: "IndexVC") as? IndexVC
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
            vc?.startSearching()

            handeled = true
        } else if (identifier == kFavoritePsalmShortcutIdentifier) {
            let songNumber = shortcutItem?.userInfo?[PFWFavoritesShortcutPsalmIdentifierKey] as? String
            let song = songsManager?.currentCollection?.songForNumber(songNumber)

            songsManager?.setcurrentSong(song, songsToDisplay: IndexVC.favoriteSongs(songsManager?.currentCollection?.songs))

            if !(navigationController?.visibleViewController is TabBarController) {
                let vc = TabBarController.pfw_instantiateFromStoryboard() as? TabBarController
                vc?.songsManager = songsManager
                if let vc = vc {
                    navigationController?.show(vc, sender: nil)
                }
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
        if window?.rootViewController?.presentedViewController is SheetMusicVC_iPhone {
            return .landscape
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            return .allButUpsideDown
        } else {
            return .portrait
        }
    }

    @objc func favoritesChanged(_ notification: Notification?) {
        updateFavoritesShortcuts()
    }

    func updateFavoritesShortcuts() {
        if let songs = songsManager?.currentCollection?.songs {
            UIApplication.shared.shortcutItems = FavoritesSyncronizer.favoriteShortcutItems(songs)
        }
    }
    
    func getAppConfig() -> [String : Any]
    {
        var dict: [String : Any]?
        
        let targetName = Bundle.main.infoDictionary?["CFBundleName"] as! String
        let dirName = targetName.lowercased() + "-resources"
        
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "AppConfig", ofType: "plist", inDirectory: dirName) ?? "")
        do {
            let x = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), options: .mutableContainersAndLeaves, format: nil)
            dict = x as? [String : Any]
        } catch {}
        
        return dict!
    }
}
