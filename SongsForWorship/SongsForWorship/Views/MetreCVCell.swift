//
//  MetreCVCell.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 11/24/19.
//  Copyright © 2019 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

class MetreCVCell: UICollectionViewCell, UIScrollViewDelegate {
    var song: Song? {
        didSet {
            titleLabel?.text = song?.title
            versesLabel?.text = {
                if
                    let line1 = song?.verses_line_1,
                    let line2 = song?.verses_line_2
                {
                    return "\(line1) \(line2)"
                }
                return nil
            }()
            metreLabel?.attributedText = song?.attributedMetreText()
            composerButton?.setTitle(song?.info_composer, for: .normal)
            
            if
                let meter = song?.meter,
                let tuneWithoutMeter = song?.tuneWithoutMeter
            {
                tuneButton?.setTitle(tuneWithoutMeter.capitalized, for: .normal)
                meterButton?.setTitle(meter.uppercased(), for: .normal)
            } else {
                tuneButton?.setTitle(song?.info_tune.capitalized, for: .normal)
                meterButton?.setTitle(nil, for: .normal)
            }
            
            scrollView?.contentOffset = .zero
        }
    }
    @IBOutlet weak var metreLabel: UILabel? {
        didSet {
            metreLabel?.font = Helper.defaultFont(withSize: 18.0)
        }
    }
    @IBOutlet weak var titleLabel: UILabel? {
        didSet {
            titleLabel?.font = Helper.defaultFont(withSize: 22.0)
        }
    }
    @IBOutlet weak var versesLabel: UILabel? {
        didSet {
            versesLabel?.font = Helper.defaultFont(withSize: 14.0)
        }
    }
    @IBOutlet weak var copyrightLabel: UILabel? {
        didSet {
            copyrightLabel?.font = Helper.defaultFont(withSize: 9.0)
        }
    }
    @IBOutlet weak var composerButton: UIButton?
    @IBOutlet weak var tuneButton: UIButton?
    @IBOutlet weak var meterButton: UIButton?
    @IBOutlet weak var scrollView: UIScrollView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        scrollView?.decelerationRate = .fast
        copyrightLabel?.text = Helper.copyrightString(nil)
    }
}
