//
//  NoRecordingsFoundTVCell.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 11/24/19.
//  Copyright © 2019 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

class NoRecordingsFoundTVCell: UITableViewCell {
    @IBOutlet weak var messageLabel: UILabel? {
        didSet {
            messageLabel?.font = {
                if
                    let settings = Settings(fromUserDefaults: .standard),
                    settings.shouldUseSystemFonts
                {
                    return UIFont.preferredFont(forTextStyle: .body)
                }
                return UIFont.systemFont(ofSize: 14.0, weight: .light)
            }()
        }
    }
}
