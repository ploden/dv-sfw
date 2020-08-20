//  Converted to Swift 5.1 by Swiftify v5.1.17924 - https://objectivec2swift.com/
//
//  PsalmsForWorshipTabBarController.m
//  PsalmsForWorship
//
//  Created by Philip Loden on 6/20/11.
//  Copyright 2011 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate, PsalmObserver {
    var songsManager: SongsManager?
    override class var storyboardName: String {
        get {
            return "SongDetail"
        }
    }
    private var isObservingcurrentSong = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor(named: "NavBarBackground")
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        navigationController?.navigationBar.compactAppearance = navigationBarAppearance
        navigationController?.navigationBar.standardAppearance = navigationBarAppearance
        
        if
            let vc = viewControllers?[0],
            let songsManager = songsManager
        {
            TabBarController.configureVC(withPsalmsManager: vc, songsToDisplay: songsManager.songsToDisplay, songsManager: songsManager)
        }
        
        delegate = self
        
        configureTitle()
        songsManager?.addObserver(forcurrentSong: self)
        isObservingcurrentSong = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureTabBar()
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    func songDidChange(_ notification: Notification) {
        if
            let object = notification.object as? SongsManager,
            object == songsManager
        {
            configureTitle()
            configureTabBar()
        }
    }
    
    // MARK: - NSObject
    deinit {
        if isObservingcurrentSong {
            songsManager?.removeObserver(forcurrentSong: self)
        }
    }
    
    // MARK: - Helper methods
    func configureTitle() {
        navigationItem.title = {
            if let number = songsManager?.currentSong?.number {
                return number
            }
            return nil
        }()
        return
    }
    
    func configureTabBar() {
        selectedViewController?.tabBarController?.tabBar.items?[1].image = {
            if
                let current = songsManager?.currentSong,
                current.isTuneCopyrighted
            {
                return UIImage(named: "no_tunes_icon", in: Helper.songsForWorshipBundle(), with: .none)
            } else {
                return UIImage(named: "tunes_icon", in: Helper.songsForWorshipBundle(), with: .none)
            }
        }()
    }
    
    // MARK: - UITabBarControllerDelegate
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if (viewController is TunesVC) {
            if songsManager?.currentSong?.isTuneCopyrighted == true {
                return false
            }
        }
        
        TabBarController.configureVC(withPsalmsManager: viewController, songsToDisplay: songsManager?.songsToDisplay, songsManager: songsManager)
        
        return true
    }
    
    class func configureVC(withPsalmsManager viewController: UIViewController?, songsToDisplay: [Song]?, songsManager: SongsManager?) {
        if var vc = viewController as? HasSongsManager {
            if vc.songsManager != songsManager {
                vc.songsManager = songsManager
            }
        }
        
        if var vc = viewController as? HasSongsToDisplay {
            if vc.songsToDisplay != songsToDisplay {
                vc.songsToDisplay = songsToDisplay
            }
        }
    }
}
