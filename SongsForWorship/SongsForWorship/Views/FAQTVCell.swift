//
//  FAQTVCell.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 11/23/19.
//  Copyright © 2019 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

class FAQTVCell: UITableViewCell {
    @IBOutlet weak var questionLabel: UILabel? {
        didSet {
            questionLabel?.font = Helper.defaultBoldFont(withSize: 14.0, forTextStyle: .body)
        }
    }
    @IBOutlet weak var answerLabel: UILabel? {
        didSet {
            answerLabel?.font = Helper.defaultFont(withSize: 14.0, forTextStyle: .body)
        }
    }
}
