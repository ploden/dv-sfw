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
            if let app = UIApplication.shared.delegate as? PsalterAppDelegate {
                metreLabel?.font = Helper.defaultFont(withSize: app.settings.fontSize)
                titleLabel?.font = Helper.defaultFont(withSize: 22.0, forTextStyle: .title3)
                versesLabel?.font = Helper.defaultFont(withSize: 14.0, forTextStyle: .body)
                copyrightLabel?.font = UIFont.systemFont(ofSize: 9.0)
            }
            
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
            //composerLabel?.text = song?.tune?.composer?.displayName
            
            if
                let meter = song?.tune?.meter,
                let tuneWithoutMeter = song?.tune?.nameWithoutMeter
            {
                //tuneButton?.setTitle(tuneWithoutMeter.capitalized, for: .normal)
                //meterButton?.setTitle(meter.uppercased(), for: .normal)
            } else {
                //tuneButton?.setTitle(song?.tune?.name.capitalized, for: .normal)
                //meterButton?.setTitle(nil, for: .normal)
            }
            
            if let left = song?.left {
                topLeftLabel?.text = left.joined(separator: "\n")
            }
            if let right = song?.right {
                topRightLabel?.text = right.joined(separator: "\n")
            }
            scrollView?.contentOffset = .zero
        }
    }
    @IBOutlet weak var metreLabel: UILabel?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var versesLabel: UILabel?
    @IBOutlet weak var copyrightLabel: UILabel?
    @IBOutlet weak var topLeftLabel: UILabel? {
        didSet {
            if let metreLabel = metreLabel {
                topLeftLabel?.font = metreLabel.font.withSize(metreLabel.font.pointSize - 4)
            }
        }
    }
    @IBOutlet weak var topRightLabel: UILabel? {
        didSet {
            if let metreLabel = metreLabel {
                topRightLabel?.font = metreLabel.font.withSize(metreLabel.font.pointSize - 4)
            }
        }
    }
    @IBOutlet weak var scrollView: UIScrollView?
    @IBOutlet weak var metadataStackView: UIStackView?
        
    override func awakeFromNib() {
        super.awakeFromNib()
        
        scrollView?.decelerationRate = .fast
        copyrightLabel?.text = Helper.copyrightString(nil)
    }
}
