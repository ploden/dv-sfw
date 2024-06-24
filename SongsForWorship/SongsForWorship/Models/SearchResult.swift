//
//  SearchResult.m
//  SongsForWorship
//
//  Created by Phil Loden on 4/26/10. Licensed under the MIT license, as follows:
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

/// A  type that represents a search result.
struct SearchResult {
    static let maxTitleLength = 90
    var title: String?
    var sourceText: String
    var songIndex: Int
    var songNumber: String
    var searchTerm: String?

    public init(sourceText: String, songIndex: Int, songNumber: String, searchTerm: String? = nil) {
        self.sourceText = sourceText
        self.songIndex = songIndex
        self.songNumber = songNumber
        self.searchTerm = searchTerm

        self.title = {
            guard
                let searchTerm = searchTerm,
                let first = sourceText.range(of: searchTerm, options: .caseInsensitive)
            else { return nil }

            var titleRange = first

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
        }()
    }
}

extension SearchResult: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(sourceText)
        hasher.combine(songNumber)
        hasher.combine(searchTerm)
    }
}
