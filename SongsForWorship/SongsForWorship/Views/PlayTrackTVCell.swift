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
                if let app = UIApplication.shared.delegate as? PsalterAppDelegate {
                    if app.settings.shouldUseSystemFonts {
                        return UIFont.preferredFont(forTextStyle: .title3)
                    }
                }
                return UIFont.systemFont(ofSize: 17.0, weight: .light)
            }()
        }
    }
}
