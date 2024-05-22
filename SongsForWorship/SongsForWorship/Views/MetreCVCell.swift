//
//  MetreCVCell.swift
//  SongsForWorship
//
//  Created by Phil Loden on 11/24/19. Licensed under the MIT license, as follows:
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import UIKit

class MetreCVCell: UICollectionViewCell, UIScrollViewDelegate {
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
    var viewModel: MetreCVCellViewModelProtocol? {
        didSet {
            configure()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        scrollView?.decelerationRate = .fast
    }

    func configure() {
        guard let viewModel = viewModel else { return }

        metreLabel?.font = viewModel.metreLabelFont
        titleLabel?.font = viewModel.titleLabelFont
        copyrightLabel?.font = viewModel.copyrightLabelFont

        titleLabel?.text = viewModel.title
        versesLabel?.text = viewModel.versesText
        metreLabel?.attributedText = viewModel.attributedMetreText
        copyrightLabel?.text = viewModel.copyrightText
        topLeftLabel?.text = viewModel.leftText
        topRightLabel?.text = viewModel.rightText
        
        scrollView?.contentOffset = .zero
    }
}
