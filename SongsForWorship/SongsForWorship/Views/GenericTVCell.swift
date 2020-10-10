//
//  GenericTVCell.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 11/23/19.
//  Copyright © 2019 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

class GenericTVCell: UITableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.textLabel?.font = Helper.defaultFont(withSize: 16.0, forTextStyle: .body)
        self.textLabel?.textAlignment = .center
    }
}
