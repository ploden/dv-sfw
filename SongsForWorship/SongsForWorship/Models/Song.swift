//
//  Psalm.m
//  PsalmsForWorship
//
//  Created by PHILIP LODEN on 4/21/10.
//  Copyright 2010 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

public struct Song {
    public private(set) var index: Int
    public private(set) var number: String
    public private(set) var title: String = ""
    public private(set) var reference: String?
    public private(set) var verses_line_1: String = ""
    public private(set) var verses_line_2: String?
    public private(set) var stanzas: [String] = [String]()
    public private(set) var pdfPageNumbers: [Int]
    public private(set) var isTuneCopyrighted: Bool = false
    public var tune: Tune?
    public private(set) var left: [String]?
    public private(set) var right: [String]?
    public private(set) var collection: SongCollection
    
    init?(fromDict dict: [AnyHashable : Any], index anIndex: Int, tune aTune: Tune, collection aCollection: SongCollection) {
        collection = aCollection
        
        index = anIndex
        tune = aTune
        
        number = dict["number"] as? String ?? ""
        title = dict["title"] as? String ?? ""
        reference = dict["reference"] as? String
        verses_line_1 = dict["verse_line_1"] as? String ?? ""
        verses_line_2 = dict["verse_line_2"] as? String ?? ""
        
        if let leftRight = dict["left_right"] as? [AnyHashable : Any] {
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
        } else if let object = dict["pdf_pages"] as? [[AnyHashable:Any]] {
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

    func attributedMetreText() -> NSAttributedString? {
        var formattedStanzas = ""
        
        for i in 0..<stanzas.count {
            formattedStanzas = formattedStanzas + stanzas[i]
            if i < stanzas.count - 1 {
                formattedStanzas = formattedStanzas + ("\n\n")
            }
        }
        
        let attrString = NSMutableAttributedString(string: formattedStanzas, attributes: nil)
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 3
        attrString.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: formattedStanzas.count))
        
        return attrString
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

