//
//  Psalm.m
//  PsalmsForWorship
//
//  Created by PHILIP LODEN on 4/21/10.
//  Copyright 2010 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

public class Song: NSObject/*, Equatable, Hashable*/ {
    var index: Int
    var number: String?
    var title: String = ""
    var reference: String?
    var verses_line_1: String = ""
    var verses_line_2: String?
    var info_composer: String = ""
    var info_tune: String = ""
    var meter: String = ""
    var tuneWithoutMeter: String?
    var stanzas: [String] = [String]()
    var pdfPageNumbers: [Int]
    var isTuneCopyrighted: Bool = false
    
    init?(fromDict dict: [AnyHashable : Any], index anIndex: Int) {
        index = anIndex

        number = dict["number"] as? String
        title = dict["title"] as? String ?? ""
        reference = dict["reference"] as? String
        verses_line_1 = dict["verse_line_1"] as? String ?? ""
        verses_line_2 = dict["verse_line_2"] as? String ?? ""
        
        info_composer = dict["info_composer"] as? String ?? ""
        info_tune = dict["info_tune"] as? String ?? ""
        meter = dict["info_meter"] as? String ?? ""
        tuneWithoutMeter = dict["info_tune_wo_meter"] as? String

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
}
