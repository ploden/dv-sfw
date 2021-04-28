//
//  PsalmsForWorshipUtil.m
//  PsalmsForWorship
//
//  Created by PHILIP LODEN on 4/18/11.
//  Copyright 2011 Deo Volente, LLC. All rights reserved.
//

import UIKit

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
            var searchResults: [SearchResult] = []

            let songNumberSearchResults = songsArray.filter { $0.number.range(of: term, options: [.caseInsensitive]) != nil }
            for result in songNumberSearchResults {
                let searchResult = SearchResult(sourceText: result.number, songIndex: result.index, songNumber: result.number, searchTerm: term)
                searchResults.append(searchResult)
            }

            let titleSearchResults = songsArray.filter { $0.title.range(of: term, options: [.caseInsensitive]) != nil }
            for result in titleSearchResults {
                let searchResult = SearchResult(sourceText: result.title, songIndex: result.index, songNumber: result.number, searchTerm: term)
                searchResults.append(searchResult)
            }

            let tuneSearchResults = songsArray.filter { $0.tune?.name.range(of: term, options: [.caseInsensitive]) != nil }
            for result in tuneSearchResults {
                if let sourceText = result.tune?.name.replacingOccurrences(of: "\n", with: " ") {
                    let searchResult = SearchResult(sourceText: sourceText, songIndex: result.index, songNumber: result.number, searchTerm: term)
                    searchResults.append(searchResult)
                }
            }

            let composerSearchResults = songsArray.filter { $0.tune?.composer?.displayName?.range(of: term, options: [.caseInsensitive]) != nil }
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
                let stanzaSearchResults = song.stanzas.filter { $0.range(of: term, options: [.caseInsensitive]) != nil }
                
                for stanza in stanzaSearchResults {
                    // for Alex if ([searchResults count] > 50) break;
                    let searchResult = SearchResult(sourceText: stanza, songIndex: song.index, songNumber: song.number, searchTerm: term)
                    searchResults.append(searchResult)
                }
            }

            let searchResultsSet = Set<SearchResult>(searchResults)
            
            DispatchQueue.main.async(execute: {
                completion(Array(searchResultsSet))
            })
        })
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
