//
//  SearchResultTVCell.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 11/24/19.
//  Copyright © 2019 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

class SearchResultTVCell: UITableViewCell {
    @IBOutlet weak var songNumberLabel: UILabel?
    @IBOutlet weak var titleLabel: UILabel? {
        didSet {
            titleLabel?.font = Helper.defaultFont(withSize: 14.0, forTextStyle: .body)
        }
    }
    var searchResult: SearchResult? {
        didSet {
            songNumberLabel?.text = searchResult?.songNumber
            titleLabel?.text = searchResult?.title
        }
    }
}
