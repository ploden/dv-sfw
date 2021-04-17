//
//  PlayTrackTVCell.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 11/23/19.
//  Copyright © 2019 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

class PlayTrackTVCell: UITableViewCell {
    @IBOutlet weak var trackTitleLabel: UILabel? {
        didSet {
            trackTitleLabel?.font = {
                let preferred = UIFont.preferredFont(forTextStyle: .body)
                return UIFont.systemFont(ofSize: preferred.pointSize, weight: .light)
            }()
        }
    }
}
