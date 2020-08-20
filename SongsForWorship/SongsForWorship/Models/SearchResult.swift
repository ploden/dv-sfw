//
//  SearchResult.m
//  PsalmsForWorship
//
//  Created by PHILIP LODEN on 4/26/10.
//  Copyright 2010 Deo Volente, LLC. All rights reserved.
//

struct SearchResult {
    static let maxTitleLength = 90
    lazy var title: String? = {
        if
            let sourceText = sourceText,
            let searchTerm = searchTerm,
            let first = sourceText.range(of: searchTerm, options: .caseInsensitive)
        {
            var titleRange = first
            let index = first
            let pre = index
            let post = index
            
            while
                sourceText.distance(from: titleRange.lowerBound, to: titleRange.upperBound) < sourceText.count,
                sourceText.distance(from: titleRange.lowerBound, to: titleRange.upperBound) < SearchResult.maxTitleLength
            {
                guard sourceText.distance(from: titleRange.lowerBound, to: titleRange.upperBound) < SearchResult.maxTitleLength else {
                    break
                }
                
                if titleRange.lowerBound != sourceText.startIndex {
                    let newLower = sourceText.index(before: titleRange.lowerBound)
                    titleRange = Range(uncheckedBounds: (lower: newLower, upper: titleRange.upperBound))
                }
                
                guard sourceText.distance(from: titleRange.lowerBound, to: titleRange.upperBound) < SearchResult.maxTitleLength else {
                    break
                }
                
                if titleRange.upperBound != sourceText.endIndex {
                    let newUpper = sourceText.index(after: titleRange.upperBound)
                    titleRange = Range(uncheckedBounds: (lower: titleRange.lowerBound, upper: newUpper))
                }
            }
            return String(sourceText[titleRange])
        }
        return nil
    }()
    var sourceText: String?
    var songIndex: Int
    var songNumber: String?
    var searchTerm: String?
    
    func song(_ allSongs: [Song]) -> Song {
        return allSongs[songIndex]
    }
}
