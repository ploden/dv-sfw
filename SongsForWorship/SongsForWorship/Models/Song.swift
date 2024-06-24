//
//  Psalm.m
//  SongsForWorship
//
//  Created by Phil Loden on 4/21/10. Licensed under the MIT license, as follows:
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

/// A  type that represents a song.
///
/// Ideally this would be a protocol,
/// but loading the type from the app config only seems
/// to work with reference types.
open class Song: SongProtocol {
    public var index: Int
    public var number: String
    public var title: String
    public var reference: String?
    public var stanzas: [String]
    public var pdfPageNumbers: [Int]
    public var isTuneCopyrighted: Bool
    public var tune: Tune?

    public init(index: Int, number: String, title: String, reference: String? = nil, stanzas: [String], pdfPageNumbers: [Int], isTuneCopyrighted: Bool, tune: Tune? = nil) {
        self.index = index
        self.number = number
        self.title = title
        self.reference = reference
        self.stanzas = stanzas
        self.pdfPageNumbers = pdfPageNumbers
        self.isTuneCopyrighted = isTuneCopyrighted
        self.tune = tune
    }

    /// Why is this here? Is it so a custom type can load itself? 
    open class func readSongs(fromFile jsonFilename: String, directory: String) -> [Song] {
        fatalError()
        return [Song]()
    }

    public func attributedMetreText() -> NSAttributedString? {
        var formattedStanzas = ""

        for idx in 0..<stanzas.count {
            formattedStanzas += stanzas[idx]
            if idx < stanzas.count - 1 {
                formattedStanzas += ("\n\n")
            }
        }

        let attrString = NSMutableAttributedString(string: formattedStanzas, attributes: nil)
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 3
        attrString.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: formattedStanzas.count))

        return attrString
    }
}

extension Song {
    public var description: String {
        return "\(type(of: self)): \(number)"
    }
}

extension Song: Equatable {
    public static func == (lhs: Song, rhs: Song) -> Bool {
        return lhs.number == rhs.number
    }
}

extension Song: Identifiable {}
