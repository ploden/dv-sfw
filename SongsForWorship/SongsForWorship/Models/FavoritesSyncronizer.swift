//
//  FavoritesSyncronizer.m
//  PsalmsForWorship
//
//  Created by Katharina on 6/2/12.
//  Copyright (c) 2012 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

extension Notification.Name {
    static let favoritesDidChange = Notification.Name("FavoritesDidChange")
}

class FavoritesSyncronizer {
    static let shared = FavoritesSyncronizer()
    
    private init() {}

    class func favorites() -> [Int] {
        if UserDefaults.standard.object(forKey: kFavoritesDictionaryName) == nil {
            UserDefaults.standard.set([Int](), forKey: kFavoritesDictionaryName)
        }
        if let favs = UserDefaults.standard.object(forKey: kFavoritesDictionaryName) as? [Int] {
            return favs
        } else {
            return [Int]()
        }
    }

    class func isFavorite(_ aSong: Song) -> Bool {
        return FavoritesSyncronizer.favorites().contains(aSong.index)
    }

    class func addToFavorites(_ aSong: Song) {
        var currentFavs: [Int] = FavoritesSyncronizer.favorites()
        currentFavs.append(aSong.index)

        currentFavs.sort(by: <)
        
        NSUbiquitousKeyValueStore.default.set(currentFavs, forKey: kFavoritesDictionaryName)
        
        UserDefaults.standard.set(currentFavs, forKey: kFavoritesDictionaryName)
        //UserDefaults.standard.set((favs as NSArray?)?.sortedArray(using: sortDescriptors), forKey: kFavoritesDictionaryName)
        NotificationCenter.default.post(name: NSNotification.Name.favoritesDidChange, object: nil)
    }

    class func removeFromFavorites(_ aSong: Song) {
        var favs = FavoritesSyncronizer.favorites()

        favs.removeAll(where: { $0 == aSong.index } )

        NSUbiquitousKeyValueStore.default.set(favs, forKey: kFavoritesDictionaryName)

        UserDefaults.standard.set(favs, forKey: kFavoritesDictionaryName)
        NotificationCenter.default.post(name: NSNotification.Name.favoritesDidChange, object: nil)
    }

    func synciCloud() {
        let store = NSUbiquitousKeyValueStore.default
        NotificationCenter.default.addObserver(self, selector: #selector(updateKVStoreItems(_:)), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: store)
        let b = store.synchronize()

        if !b {
        #if DEBUG
            //throw NSException(name: NSExceptionName("FavoritesSyncronizerException"), reason: "synchronize returned false", userInfo: nil) as! Error
        #endif
        }
    }

    @objc func updateKVStoreItems(_ notification: Notification?) {
        // Get the list of keys that changed.
        let userInfo = notification?.userInfo
        
        if let reasonForChange = userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber {
            // Update only for changes from the server.
            let reason = reasonForChange.intValue
            
            if (reason == NSUbiquitousKeyValueStoreServerChange) || (reason == NSUbiquitousKeyValueStoreInitialSyncChange) {
                // If something is changing externally, get the changes
                // and update the corresponding keys locally.
                let changedKeys = userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [AnyHashable]
                let store = NSUbiquitousKeyValueStore.default
                let userDefaults = UserDefaults.standard
                
                // This loop assumes you are using the same key names in both
                // the user defaults database and the iCloud key-value store
                for key in changedKeys ?? [] {
                    guard let key = key as? String else {
                        continue
                    }
                    let value = store.object(forKey: key)
                    userDefaults.set(value, forKey: key)
                }
                
                NotificationCenter.default.post(name: NSNotification.Name.favoritesDidChange, object: nil)
            }
        }
    }
}

extension FavoritesSyncronizer {
    static func favoriteShortcutItems(_ allSongs: [Song]) -> [UIApplicationShortcutItem] {
        var shortcuts = [UIApplicationShortcutItem]()
        
        for fav in Array(FavoritesSyncronizer.favorites().prefix(3)) {
            if
                let favPsalm = SongsManager.songAtIndex(fav, allSongs: allSongs),
                let songNumber = favPsalm.number
            {
                let shortcut = UIApplicationShortcutItem(type: kFavoritePsalmShortcutIdentifier, localizedTitle: favPsalm.title, localizedSubtitle: songNumber, icon: nil, userInfo: [PFWFavoritesShortcutPsalmIdentifierKey: songNumber as NSString])
                shortcuts.append(shortcut)
            }
        }
        
        return shortcuts
    }

}
