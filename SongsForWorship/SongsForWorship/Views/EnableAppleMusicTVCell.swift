//
//  EnableAppleMusicTVCell.swift
//  SongsForWorship
//
//  Created by Philip Loden on 4/13/21.
//  Copyright © 2021 Deo Volente, LLC. All rights reserved.
//

import UIKit

class EnableAppleMusicTVCell: UITableViewCell {

    @IBOutlet weak var enableAppleMusicSwitch: UISwitch? {
        didSet {
            enableAppleMusicSwitch?.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }
    }
    
}
