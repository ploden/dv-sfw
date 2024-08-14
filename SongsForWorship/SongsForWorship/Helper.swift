//
//  SongsForWorshipUtil.m
//  SongsForWorship
//
//  Created by Phil Loden on 4/18/11.
//  Copyright 2011 Deo Volente, LLC. All rights reserved.
//

import UIKit
import OrderedCollections

let nonnullIsNilErrorMessage = "nonnull is nil"
var playbackRates = [0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4]
var numPlaybackRates: size_t = 6

public class Helper: NSObject {
    public class func defaultFont(withSize size: CGFloat, appConfig: AppConfig, settings: Settings) -> UIFont {
        if settings.shouldUseSystemFonts {
            return UIFont.systemFont(ofSize: size)
        } else if let font = UIFont(name: appConfig.defaultFont, size: size) {
            return font
        }

        return UIFont.systemFont(ofSize: size)
    }

    public class func defaultFont(withSize size: CGFloat,
                           forTextStyle textStyle: UIFont.TextStyle,
                           appConfig: AppConfig,
                           settings: Settings) -> UIFont
    {
        let preferredFont = UIFont.preferredFont(forTextStyle: textStyle)

        if settings.shouldUseSystemFonts {
            return preferredFont
        } else if let font = UIFont(name: appConfig.defaultFont, size: preferredFont.pointSize) {
            return font
        }

        return UIFont.systemFont(ofSize: preferredFont.pointSize)
    }

    class func defaultBoldFont(withSize size: CGFloat,
                               forTextStyle textStyle: UIFont.TextStyle,
                               appConfig: AppConfig,
                               settings: Settings) -> UIFont
    {
        let preferredFont = UIFont.preferredFont(forTextStyle: textStyle)

        if settings.shouldUseSystemFonts {
            return preferredFont
        } else if let font = UIFont(name: appConfig.defaultBoldFont, size: preferredFont.pointSize) {
            return font
        }

        return UIFont.boldSystemFont(ofSize: preferredFont.pointSize)
    }

    class func searchResults(forTerm term: String, songsArray: [Song]) async -> [SearchResult]? {
        let searchTask = Task { () -> [SearchResult]? in
            var searchResultsAttributes = [(result: SearchResult, attribute: SearchableAttribute)]()

            for song in songsArray {
                let attributes = song.searchableAttributes

                for attribute in attributes {
                    let haystack = attribute.attribute
                    if Self.isMatch(haystack: haystack, needle: term) {
                        let searchResult = SearchResult(sourceText: haystack, songIndex: song.index, songNumber: song.number, searchTerm: term)
                        searchResultsAttributes.append((result: searchResult, attribute: attribute))
                    }
                }
            }

            let sortedSearchResultsAttributes = searchResultsAttributes.sorted(using: KeyPathComparator(\.attribute.priority, order: .reverse))

            return sortedSearchResultsAttributes.compactMap { $0.result }
        }

        return await searchTask.value
    }

    class func isMatch(haystack: String?, needle: String?) -> Bool {
        guard let haystack = haystack, let needle = needle else {
            return false
        }

        return haystack.range(of: needle, options: [.caseInsensitive]) != nil
    }

    class func songsForWorshipBundle() -> Bundle {
        return Bundle(identifier: "com.deovolentellc.SongsForWorship")!
    }

    class func mainStoryboardForiPhone() -> UIStoryboard {
        return UIStoryboard(name: "Main_iPhone", bundle: Helper.songsForWorshipBundle())
    }

    class func mainStoryboard_iPad() -> UIStoryboard {
        return UIStoryboard(name: "Main_iPad", bundle: Helper.songsForWorshipBundle())
    }
}
