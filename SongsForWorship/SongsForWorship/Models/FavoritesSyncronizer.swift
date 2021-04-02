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

    private class func favorites() -> [Int]? {
        if let favs = UserDefaults.standard.object(forKey: kFavoritesDictionaryName) as? [Int] {
            return favs
        }
        return nil
    }

    class func favoriteSongNumbers(songsManager: SongsManager) -> [String] {
        if UserDefaults.standard.object(forKey: kFavoriteSongNumbersDictionaryName) == nil {
            UserDefaults.standard.set([String](), forKey: kFavoriteSongNumbersDictionaryName)
        }
        if let favs = UserDefaults.standard.object(forKey: kFavoriteSongNumbersDictionaryName) as? [String] {
            if let oldFavorites = favorites() {
                let oldFavoriteSongs = oldFavorites.compactMap { songIdx in
                    songsManager.songCollections.first?.songs?.first(where: { songIdx == $0.index })
                }
                let oldFavoriteNumbers = oldFavoriteSongs.map { $0.number }
                
                let combined: Set<String> = Set(oldFavoriteNumbers).union(Set(favs))
                return  combined.sorted { return $0.localizedStandardCompare($1) == ComparisonResult.orderedAscending }
            } else {
                return favs.sorted { return $0.localizedStandardCompare($1) == ComparisonResult.orderedAscending }
            }
        } else {
            return [String]()
        }
    }
    
    class func isFavorite(_ aSong: Song, songsManager: SongsManager) -> Bool {
        if FavoritesSyncronizer.favorites()?.contains(aSong.index) == true {
            return true
        } else {
            return FavoritesSyncronizer.favoriteSongNumbers(songsManager: songsManager).contains(aSong.number)
        }
    }

    class func addToFavorites(_ aSong: Song, songsManager: SongsManager) {
        var currentFavs: [String] = FavoritesSyncronizer.favoriteSongNumbers(songsManager: songsManager)
        currentFavs.append(aSong.number)
        let currentFavsSet = Set(currentFavs)
        
        NSUbiquitousKeyValueStore.default.set(currentFavsSet.sorted { return $0.localizedStandardCompare($1) == ComparisonResult.orderedAscending }, forKey: kFavoriteSongNumbersDictionaryName)
        UserDefaults.standard.set(currentFavs, forKey: kFavoriteSongNumbersDictionaryName)
        NotificationCenter.default.post(name: NSNotification.Name.favoritesDidChange, object: nil)
    }

    class func removeFromFavorites(_ aSong: Song, songsManager: SongsManager) {
        if var favs = FavoritesSyncronizer.favorites() {
            favs.removeAll(where: { $0 == aSong.index } )
            
            NSUbiquitousKeyValueStore.default.set(favs, forKey: kFavoritesDictionaryName)
            UserDefaults.standard.set(favs, forKey: kFavoritesDictionaryName)
            NotificationCenter.default.post(name: NSNotification.Name.favoritesDidChange, object: nil)
        }
        
        var favoriteSongNumbers = FavoritesSyncronizer.favoriteSongNumbers(songsManager: songsManager)
        
        favoriteSongNumbers.removeAll(where: { $0 == aSong.number } )
        
        NSUbiquitousKeyValueStore.default.set(favoriteSongNumbers, forKey: kFavoriteSongNumbersDictionaryName)
        UserDefaults.standard.set(favoriteSongNumbers, forKey: kFavoriteSongNumbersDictionaryName)
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
    static func favoriteShortcutItems(_ allSongs: [Song], songsManager: SongsManager) -> [UIApplicationShortcutItem] {
        var shortcuts = [UIApplicationShortcutItem]()
        
        for fav in Array(FavoritesSyncronizer.favoriteSongNumbers(songsManager: songsManager).prefix(3)) {
            if let favPsalm = songsManager.songForNumber(fav) {
                let shortcut = UIApplicationShortcutItem(type: kFavoritePsalmShortcutIdentifier, localizedTitle: favPsalm.title, localizedSubtitle: favPsalm.number, icon: nil, userInfo: [PFWFavoritesShortcutPsalmIdentifierKey: favPsalm.number as NSString])
                shortcuts.append(shortcut)
            }
        }
        
        return shortcuts
    }

}
