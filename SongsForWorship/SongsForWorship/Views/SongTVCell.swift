//
//  PsalmCell.swift
//  PsalmsForWorship
//
//  Created by PHILIP LODEN on 4/23/10.
//  Copyright 2010 Deo Volente, LLC. All rights reserved.
//

import UIKit

class SongTVCell: UITableViewCell {
    @IBOutlet private weak var numberLabel: UILabel?
    @IBOutlet private weak var referenceLabel: UILabel?
    @IBOutlet private weak var titleLabel: UILabel?
    @IBOutlet private weak var favoriteButton: UIButton?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        numberLabel?.font = Helper.defaultFont(withSize: 22.0, forTextStyle: .title2)
        
        referenceLabel?.font = Helper.defaultFont(withSize: 10.0, forTextStyle: .footnote)
        referenceLabel?.textColor = UIColor.gray
        referenceLabel?.highlightedTextColor = UIColor.white
        
        titleLabel?.font = Helper.defaultFont(withSize: 16.0, forTextStyle: .title3)
        titleLabel?.highlightedTextColor = UIColor.white
    }
    
    func configureWithPsalm(_ aSong: Song?, isFavorite: Bool) {
        numberLabel?.text = aSong?.number
        
        referenceLabel?.text = {
            if let ref = aSong?.reference {
                if let _ = ref.rangeOfCharacter(from: CharacterSet(charactersIn: "-")) {
                    return "Ps. \(ref)"
                } else {
                    return "Psalm \(ref)"
                }
            }
            return ""
        }()
        
        titleLabel?.text = aSong?.title
        
        favoriteButton?.isHidden = !isFavorite
    }
    
    @IBAction func favoriteButtonTapped(_ sender: Any) {
        UIApplication.shared.sendAction(#selector(SongIndexVC.songTVCellFavoriteButtonTapped(_:)), to: nil, from: self, for: nil)
    }
}
