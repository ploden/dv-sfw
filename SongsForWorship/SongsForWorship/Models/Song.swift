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

/*
 {
     "info_composer": "Lucy Broadwood; harm. Ralph Vaughan-Williams, 1906",
     "info_tune": "KINGSFOLD CMD Copyright Oxford University Press. Used by permission",
     "reference": "26",
     "title": "LORD, Vindicate Me",
     "verse_line_1": "Which of you convicts Me of sin? And if I tell the truth,",
     "pdf_page_nums": [
         96
     ],
     "verse_line_2": "why do you not believe Me? -John 8:46",
     "stanzas": [
         "1. LORD, vindicate me; I have walked \nIn my integrity.\nAnd I have trusted in the LORD;\nI've been unwavering.\nExamine me and prove me, LORD; \nTest heart and mind, I pray.\nSince I behold Your steadfast love;\nYour truth has led my way.",
         "2. I will not be with worthless men, \nNor with the hypocrite.\nI hate the crowd of wicked men;\nWith evil I'll not sit.\nI'll guiltless wash my hands and come\nBefore Your altar, LORD.\nAnd I will shout with thankful voice;\nYour wonders I'll record.",
         "3. O LORD, I love Your dwelling place;\nYour house is my delight.\nThe place in which Your glory dwells\nIs lovely in my sight.\nWith sinners do not take my soul,\nWith men who blood have spilled.\nTheir hands perform a wicked scheme;\nTheir hands with bribes are filled.",
         "4. But I have set myself to walk \nIn my integrity;\nO deal with me in graciousness,\nRedeem and set me free.\nMy foot now stands on level ground,\nA place of uprightness;\nAnd where the congregation meets, \nThe LORD I there will bless."
     ],
     "number": "26A",
     "is_tune_copyrighted": true
 }
 */

/*
 {
     "number": "1A",
     "title": "That Man Is Blest",
     "stanzas": [
         "1. That man is blest who, fearing God,\nfrom sin restrains his feet,\nwho will not stand with wicked men,\nwho shuns the scorners\u2019 seat.",
         "2. Yea, blest is he who makes God\u2019s law\nhis portion and delight,\nand meditates upon that law\nwith gladness day and night.",
         "3. That man is nourished like a tree\nset by the river\u2019s side;\nits leaf is green, its fruit is sure,\nand thus his works abide.",
         "4. The wicked, like the driven chaff,\nare swept from off the land;\nthey shall not gather with the just,\nnor in the judgment stand.",
         "5. The Lord will guard the righteous well,\ntheir way to him is known;\nthe way of sinners, far from God,\nshall surely be o\u2019erthrown."
     ],
     "reference": "1",
     "tune": "MEDITATION",
     "pdf_pages": [
         {
             "number": 1,
             "music_start": 0.09142486103485623,
             "music_end": 0.5667805727066533
         }
     ],
     "left_right": {
         "left": [
             "The Psalter, 1912"
         ],
         "right": [
             "MEDITATION C.M.",
             "John H. Gower, 1890"
         ]
     }
 }
 */

import Foundation
import UIKit

open class Song {
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
    
    /*
    public private(set) var left: [String]?
    public private(set) var right: [String]?
     */

    /*
    init?(fromDict dict: [AnyHashable: Any], index anIndex: Int, tune aTune: Tune) {
        index = anIndex
        tune = aTune

        number = dict["number"] as? String ?? ""
        title = dict["title"] as? String ?? ""
        reference = dict["reference"] as? String
        versesLine1 = dict["verse_line_1"] as? String ?? ""
        versesLine2 = dict["verse_line_2"] as? String ?? ""

        if let leftRight = dict["left_right"] as? [AnyHashable: Any] {
            left = leftRight["left"] as? [String]
            right = leftRight["right"] as? [String]
        }

        stanzas = [String]()

        if let object = dict["stanzas"] as? [String] {
            for stanza in object {
                stanzas.append(stanza)
            }
        }

        pdfPageNumbers = [Int]()

        if let object = dict["pdf_page_nums"] as? [Int] {
            for pageNum in object {
                pdfPageNumbers.append(pageNum)
            }
        } else if let object = dict["pdf_pages"] as? [[AnyHashable: Any]] {
            for page in object {
                if let pageNum = page["number"] as? Int {
                    pdfPageNumbers.append(pageNum)
                }
            }
        }

        if let object = dict["is_tune_copyrighted"] as? Bool {
            isTuneCopyrighted = object
        } else {
            isTuneCopyrighted = false
        }
    }
     */

    /*
    public func new(with tune: Tune?) -> Song {
        var newSelf = self
        newSelf.tune = tune
        return newSelf
    }
     */
}

extension Song {

    public func new(with tune: Tune?) -> Song {
        var newSelf = self
        newSelf.tune = tune
        return newSelf
    }

    public var description: String {
        return "\(type(of: self)): \(number)"
    }
    
}

extension Song: Equatable {
    public static func == (lhs: Song, rhs: Song) -> Bool {
        return lhs.number == rhs.number
    }
}

extension Song: Identifiable {
    
}
