//
//  EnableMusicLibraryTVCell.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 11/23/19.
//  Copyright © 2019 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

class EnableMusicLibraryTVCell: UITableViewCell {
    @IBOutlet weak var enableMusicLibrarySwitch: UISwitch? {
        didSet {
            enableMusicLibrarySwitch?.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }
    }
}
