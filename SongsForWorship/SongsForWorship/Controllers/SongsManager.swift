//
//  SongsManager.swift
//  SongsForWorship
//
//  Created by Phil Loden on 3/30/20. Licensed under the MIT license, as follows:
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

public class SongsManager: Equatable {
    public static func == (lhs: SongsManager, rhs: SongsManager) -> Bool {
        return lhs.songCollections == rhs.songCollections &&
            lhs.currentSong == rhs.currentSong &&
            lhs.songsToDisplay == rhs.songsToDisplay
    }

    var songCollections: [SongCollection<Song>]
    var currentSong: Song?
    var songsToDisplay: [Song]?

    init(appConfig: AppConfig) {
        self.songCollections = appConfig.songCollections.compactMap { collection in
            var collectionSections = [SongCollectionSection]()

            let sections = collection.sections

            for section in sections {
                let newSection = SongCollectionSection(title: section.title, count: section.count)
                collectionSections.append(newSection)
            }
            
            let songs = appConfig.songClass.readSongs(fromFile: collection.jsonFilename, directory: appConfig.directory)

            let newCollection = SongCollection<Song>(songs: songs, directory: appConfig.directory, collectionConfig: collection, pdfRenderingConfigsForiPhone: appConfig.pdfRenderingConfigsForiPhone, pdfRenderingConfigsForiPad: appConfig.pdfRenderingConfigsForiPad)

            return newCollection
        }
    }

    func setcurrentSong(_ currentSong: Song?, songsToDisplay: [Song]?) {
        if self.currentSong != currentSong || self.songsToDisplay != songsToDisplay {
            let previousSong = self.currentSong
            self.currentSong = currentSong
            self.songsToDisplay = songsToDisplay
            let userInfo = [NotificationUserInfoKeys.oldValue: previousSong, NotificationUserInfoKeys.newValue: self.currentSong]
            NotificationCenter.default.post(name: .currentSongDidChange, object: self, userInfo: userInfo as [AnyHashable: Any])
        }
    }

    func addObserver(forSelectedCollection anObserver: SongCollectionObserver?) {
        NotificationCenter.default.addObserver(anObserver as Any,
                                               selector: #selector(SongCollectionObserver.selectedCollectionDidChange),
                                               name: .selectedCollectionDidChange, object: nil)
    }

    func removeObserver(forSelectedCollection anObserver: SongCollectionObserver?) {
        NotificationCenter.default.removeObserver(anObserver as Any, name: .selectedCollectionDidChange, object: nil)
    }

    func addObserver(forcurrentSong anObserver: PsalmObserver?) {
        NotificationCenter.default.addObserver(anObserver as Any,
                                               selector: #selector(PsalmObserver.songDidChange(_:)),
                                               name: .currentSongDidChange,
                                               object: nil)
    }

    func removeObserver(forcurrentSong anObserver: PsalmObserver?) {
        NotificationCenter.default.removeObserver(anObserver as Any, name: .currentSongDidChange, object: nil)
    }

    func songForNumber(_ number: String?) -> (Song)? {
        for collection in songCollections {
            if let match = collection.song(for: number) {
                return match
            }
        }
        return nil
    }

    func collection(forSong song: Song) -> SongCollection<Song>? {
        return songCollections.first(where: { $0.songs.contains(song) })
    }

}
