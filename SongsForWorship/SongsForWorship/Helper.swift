//
//  PsalmsForWorshipUtil.m
//  PsalmsForWorship
//
//  Created by PHILIP LODEN on 4/18/11.
//  Copyright 2011 Deo Volente, LLC. All rights reserved.
//

import UIKit
import OrderedCollections

let NonnullIsNilErrorMessage = "nonnull is nil"
var PlaybackRates = [0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4]
var NumPlaybackRates: size_t = 6

class Helper: NSObject {
    class func defaultFont(withSize size: CGFloat) -> UIFont {
        if
            let app = UIApplication.shared.delegate as? SFWAppDelegate,
            let settings = Settings(fromUserDefaults: .standard)
        {
            if settings.shouldUseSystemFonts {
                return UIFont.systemFont(ofSize: size)
            } else if
                let font = UIFont(name: app.appConfig.defaultFont, size: size)
            {
                return font
            }
        }
        
        return UIFont.systemFont(ofSize: size)
    }
    
    class func defaultFont(withSize size: CGFloat, forTextStyle textStyle: UIFont.TextStyle) -> UIFont {
        if
            let app = UIApplication.shared.delegate as? SFWAppDelegate,
            let settings = Settings(fromUserDefaults: .standard)
        {
            let preferredFont = UIFont.preferredFont(forTextStyle: textStyle)
            
            if settings.shouldUseSystemFonts {
                return preferredFont
            } else if
                let font = UIFont(name: app.appConfig.defaultFont, size: preferredFont.pointSize)
            {
                return font
            }
            
            return UIFont.systemFont(ofSize: preferredFont.pointSize)
        }
        
        return UIFont.systemFont(ofSize: size)
    }

    class func defaultBoldFont(withSize size: CGFloat, forTextStyle textStyle: UIFont.TextStyle) -> UIFont {
        if
            let app = UIApplication.shared.delegate as? SFWAppDelegate,
            let settings = Settings(fromUserDefaults: .standard)
        {
            let preferredFont = UIFont.preferredFont(forTextStyle: textStyle)

            if settings.shouldUseSystemFonts {
                return preferredFont
            } else if                
                let font = UIFont(name: app.appConfig.defaultBoldFont, size: preferredFont.pointSize)
            {
                return font
            }
            
            return UIFont.boldSystemFont(ofSize: preferredFont.pointSize)
        }
        
        return UIFont.boldSystemFont(ofSize: size)
    }

    class func searchResultsForTerm(_ term: String, songsArray: [Song], completion: @escaping ([SearchResult]?) -> Void) {
        let queue = DispatchQueue.global(qos: .default)

        queue.async(execute: {
            var searchResults = [SearchResult]()

            let titleSearchResults = songsArray.compactMap {
                let haystack = $0.title
                if Self.isMatch(haystack: haystack, needle: term) {
                    let searchResult = SearchResult(sourceText: haystack, songIndex: $0.index, songNumber: $0.number, searchTerm: term)
                    return searchResult
                }
                return nil
            }
            
            searchResults.append(contentsOf: titleSearchResults)
            
            let songNumberSearchResults = songsArray.compactMap {
                let haystack = $0.number
                if Self.isMatch(haystack: haystack, needle: term) {
                    let searchResult = SearchResult(sourceText: haystack, songIndex: $0.index, songNumber: $0.number, searchTerm: term)
                    return searchResult
                }
                return nil
            }
            
            searchResults.append(contentsOf: songNumberSearchResults)

            let tuneSearchResults = songsArray.compactMap {
                if
                    let haystack = $0.tune?.name.replacingOccurrences(of: "\n", with: " "),
                    Self.isMatch(haystack: haystack, needle: term)
                {
                    let searchResult = SearchResult(sourceText: haystack, songIndex: $0.index, songNumber: $0.number, searchTerm: term)
                    return searchResult
                }
                return nil
            }
            
            searchResults.append(contentsOf: tuneSearchResults)

            let composerSearchResults = songsArray.filter { Self.isMatch(haystack: $0.tune?.composer?.displayName, needle: term) }
            for result in composerSearchResults {
                if let sourceText = result.tune?.composer?.displayName?.replacingOccurrences(of: "\n", with: " ") {
                    let searchResult = SearchResult(sourceText: sourceText, songIndex: result.index, songNumber: result.number, searchTerm: term)
                    searchResults.append(searchResult)
                }
            }

            let leftSearchResults = songsArray.filter { $0.left?.joined(separator: " ").range(of: term, options: [.caseInsensitive]) != nil }
            for result in leftSearchResults {
                if let sourceText = result.left?.joined(separator: " ").replacingOccurrences(of: "\n", with: " ") {
                    let searchResult = SearchResult(sourceText: sourceText, songIndex: result.index, songNumber: result.number, searchTerm: term)
                    searchResults.append(searchResult)
                }
            }
            
            let rightSearchResults = songsArray.filter { $0.right?.joined(separator: " ").range(of: term, options: [.caseInsensitive]) != nil }
            for result in rightSearchResults {
                if let sourceText = result.right?.joined(separator: " ").replacingOccurrences(of: "\n", with: " ") {
                    let searchResult = SearchResult(sourceText: sourceText, songIndex: result.index, songNumber: result.number, searchTerm: term)
                    searchResults.append(searchResult)
                }
            }
            
            for song in songsArray {
                for stanza in song.stanzas {
                    let lines = stanza.components(separatedBy: .newlines)
                    
                    for line in lines {
                        let haystack = line
                        if
                            Self.isMatch(haystack: haystack, needle: term)
                        {
                            let searchResult = SearchResult(sourceText: haystack, songIndex: song.index, songNumber: song.number, searchTerm: term)
                            searchResults.append(searchResult)
                        }
                    }
                }
            }
            
            DispatchQueue.main.async(execute: {
                completion(searchResults)
            })
        })
    }

    class func isMatch(haystack: String?, needle: String?) -> Bool {
        guard let haystack = haystack, let needle = needle else {
            return false
        }
        
        return haystack.range(of: needle, options: [.caseInsensitive]) != nil

        let matcher = SmartSearchMatcher(searchString: haystack)
        return matcher.matches(needle)
    }
    
    class func songsForWorshipBundle() -> Bundle {
        return Bundle(identifier: "com.deovolentellc.SongsForWorship")!
    }
    
    class func mainStoryboard_iPhone() -> UIStoryboard {
        return UIStoryboard(name: "Main_iPhone", bundle: Helper.songsForWorshipBundle())
    }

    class func mainStoryboard_iPad() -> UIStoryboard {
        return UIStoryboard(name: "Main_iPad", bundle: Helper.songsForWorshipBundle())
    }

    class func copyrightString(_ now: Date?) -> String {
        let nonnullNow = now ?? Date()

        let cal = Calendar.current
        let yearComponent = cal.component(Calendar.Component.year, from: nonnullNow)

        if let app = UIApplication.shared.delegate as? SFWAppDelegate {
            let copyright = app.appConfig.copyright
            return String(format: "© %ld \(copyright).\nUsed with permission.", yearComponent)
        } else {
            return String(format: "© %ld.\nUsed with permission.", yearComponent)
        }
    }
}

//
//  SmartSearchMatcher.swift
//  SmartSearchExample
//
//  Created by Geoff Hackworth on 23/01/2021. Licensed under the MIT license, as follows:
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

/// Search string matcher using token prefixes.
struct SmartSearchMatcher {

    /// Creates a new instance for testing matches against `searchString`.
    public init(searchString: String) {
        // Split `searchString` into tokens by whitespace and sort them by decreasing length
        searchTokens = searchString.split(whereSeparator: { $0.isWhitespace }).sorted { $0.count > $1.count }
    }

    /// Check if `candidateString` matches `searchString`.
    func matches(_ candidateString: String) -> Bool {
        // If there are no search tokens, everything matches
        guard !searchTokens.isEmpty else { return false }

        // Split `candidateString` into tokens by whitespace
        var candidateStringTokens = candidateString.split(whereSeparator: { $0.isWhitespace })

        // Iterate over each search token
        for searchToken in searchTokens {
            // We haven't matched this search token yet
            var matchedSearchToken = false

            // Iterate over each candidate string token
            for (candidateStringTokenIndex, candidateStringToken) in candidateStringTokens.enumerated() {
                // Does `candidateStringToken` start with `searchToken`?
                if let range = candidateStringToken.range(of: searchToken, options: [.caseInsensitive, .diacriticInsensitive]),
                   range.lowerBound == candidateStringToken.startIndex {
                    matchedSearchToken = true

                    // Remove the candidateStringToken so we don't match it again against a different searchToken.
                    // Since we sorted the searchTokens by decreasing length, this ensures that searchTokens that
                    // are equal or prefixes of each other don't repeatedly match the same `candidateStringToken`.
                    // I.e. the longest matches are "consumed" so they don't match again. Thus "c c" does not match
                    // a string unless there are at least two words beginning with "c", and "b ba" will match
                    // "Bill Bailey" but not "Barry Took"
                    candidateStringTokens.remove(at: candidateStringTokenIndex)

                    // Check the next search string token
                    break
                }
            }

            // If we failed to match `searchToken` against the candidate string tokens, there is no match
            guard matchedSearchToken else { return false }
        }

        // If we match every `searchToken` against the candidate string tokens, `candidateString` is a match
        return true
    }

    private(set) var searchTokens: [String.SubSequence]
}
