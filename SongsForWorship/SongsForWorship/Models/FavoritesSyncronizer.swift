//
//  FavoritesSyncronizer.m
//  SongsForWorship
//
//  Created by Katharina on 6/2/12. Licensed under the MIT license, as follows:
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

extension Notification.Name {
    static let favoritesDidChange = Notification.Name("FavoritesDidChange")
}

enum SFWError: Error {
    case runtimeError(String)
}

public class FavoritesSyncronizer {
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
                    songsManager.songCollections.first?.songs.first(where: { songIdx == $0.index })
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

        let sortedCurrentFavs = currentFavsSet.sorted { return $0.localizedStandardCompare($1) == ComparisonResult.orderedAscending }

        NSUbiquitousKeyValueStore.default.set(sortedCurrentFavs, forKey: kFavoriteSongNumbersDictionaryName)
        UserDefaults.standard.set(currentFavs, forKey: kFavoriteSongNumbersDictionaryName)
        NotificationCenter.default.post(name: NSNotification.Name.favoritesDidChange, object: nil)
    }

    class func removeFromFavorites(_ aSong: Song, songsManager: SongsManager) {
        if var favs = FavoritesSyncronizer.favorites() {
            favs.removeAll(where: { $0 == aSong.index })

            NSUbiquitousKeyValueStore.default.set(favs, forKey: kFavoritesDictionaryName)
            UserDefaults.standard.set(favs, forKey: kFavoritesDictionaryName)
        }

        var favoriteSongNumbers = FavoritesSyncronizer.favoriteSongNumbers(songsManager: songsManager)

        favoriteSongNumbers.removeAll(where: { $0 == aSong.number })

        NSUbiquitousKeyValueStore.default.set(favoriteSongNumbers, forKey: kFavoriteSongNumbersDictionaryName)
        UserDefaults.standard.set(favoriteSongNumbers, forKey: kFavoriteSongNumbersDictionaryName)
        NotificationCenter.default.post(name: NSNotification.Name.favoritesDidChange, object: nil)
    }

    func synciCloud() throws {
        print("FavoritesSyncronizer: synciCloud")
        let store = NSUbiquitousKeyValueStore.default
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateKVStoreItems(notification:)),
                                               name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                                               object: store)

        if store.synchronize() == false {
            throw SFWError.runtimeError("FavoritesSyncronizer: synchronize returned false")
        }
    }

    @objc func updateKVStoreItems(notification: Notification?) {
        print("FavoritesSyncronizer: updateKVStoreItems")
        // Get the list of keys that changed.
        let userInfo = notification?.userInfo

        if let reasonForChange = userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber {
            // Update only for changes from the server.
            let reason = reasonForChange.intValue

            if (reason == NSUbiquitousKeyValueStoreServerChange) || (reason == NSUbiquitousKeyValueStoreInitialSyncChange) {
                print("FavoritesSyncronizer: updateKVStoreItems: NSUbiquitousKeyValueStoreServerChange or NSUbiquitousKeyValueStoreInitialSyncChange")
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
                let shortcut = UIApplicationShortcutItem(type: kFavoritePsalmShortcutIdentifier,
                                                         localizedTitle: favPsalm.title,
                                                         localizedSubtitle: favPsalm.number,
                                                         icon: nil,
                                                         userInfo: [PFWFavoritesShortcutPsalmIdentifierKey: favPsalm.number as NSString])
                shortcuts.append(shortcut)
            }
        }

        return shortcuts
    }

}
