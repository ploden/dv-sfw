//
//  PlayerControlsView.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 5/2/11.
//  Copyright 2011 Deo Volente, LLC. All rights reserved.
//

import UIKit

var PFWPlaybackRates: [Float] = [0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4]
var PFWNumPlaybackRates: size_t = 6

class PlayerControlsView: UIView {
    weak var delegate: PlayerControlsViewDelegate?
    @IBOutlet private weak var playbackRateSegmentedControl: UISegmentedControl? {
        didSet {
            let font = UIFont.boldSystemFont(ofSize: 12.0)
            let normalAttribute: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.white]
            playbackRateSegmentedControl?.setTitleTextAttributes(normalAttribute, for: .normal)
            let selectedAttribute: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.black]
            playbackRateSegmentedControl?.setTitleTextAttributes(selectedAttribute, for: .selected)
        }
    }
    @IBOutlet private weak var volumeSlider: UISlider?
    @IBOutlet weak var loopButton: UIButton?
    @IBOutlet weak var prevButton: UIButton?
    @IBOutlet weak var playButton: UIButton?
    @IBOutlet weak var nextButton: UIButton?
    @IBOutlet weak var trackTitleLabel: UILabel?
    @IBOutlet weak var timeElapsedLabel: UILabel?
    @IBOutlet weak var timeRemainingLabel: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()

        playbackRateSegmentedControl?.removeAllSegments()

        let defaultRate: Float = 1.0
        var defaultIdx = 0

        for i in 0..<PFWNumPlaybackRates {
            let title = PlayerControlsView.displayStringForPlaybackRate(PFWPlaybackRates[i])
            playbackRateSegmentedControl?.insertSegment(withTitle: title, at: Int(i), animated: false)

            if defaultRate == PFWPlaybackRates[i] {
                defaultIdx = Int(i)
            }
        }

        playbackRateSegmentedControl?.selectedSegmentIndex = defaultIdx
    }

    @IBAction func loopButtonPressed() {
        delegate?.loopButtonPressed()
    }

    @IBAction func playButtonPressed() {
        delegate?.playButtonPressed()
    }

    @IBAction func prevButtonPressed() {
        delegate?.prevButtonPressed()
    }

    @IBAction func nextButtonPressed() {
        delegate?.nextButtonPressed()
    }

    @IBAction func playbackRateSegmentedControlValueChanged(_ sender: Any) {
        delegate?.playbackRateDidChange()
    }

    func configure(withCurrentPlaybackRate rate: PFWPlaybackRate) {}

    func currentPlaybackRate() -> PFWPlaybackRate {
        return PFWPlaybackRate(PFWPlaybackRates[playbackRateSegmentedControl?.selectedSegmentIndex ?? 0])
    }

    func configureLoopButtonWithNumber(_ number: NSNumber?) {
        if let number = number {
            if number.intValue <= 0 || number.intValue > 9 {
                loopButton?.isSelected = false
            } else {
                loopButton?.isSelected = true
                
                let loopIcon = UIImage(named: "loop_icon", in: Helper.songsForWorshipBundle(), with: .none)
                
                let cSize = CGSize(width: loopIcon?.size.width ?? 0.0, height: loopIcon?.size.height ?? 0.0)
                UIGraphicsBeginImageContextWithOptions(cSize, _: false, _: UIScreen.main.scale)
                let ctx = UIGraphicsGetCurrentContext()
                UIColor.clear.set()
                ctx?.fill(CGRect(x: 0, y: 0, width: cSize.width, height: cSize.height))
                loopIcon?.draw(at: CGPoint(x: 0, y: 0))
                
                UIColor.white.set()
                let circleRect = CGRect(x: 3.0, y: 11.0, width: 14.0, height: 14.0)
                ctx?.addEllipse(in: circleRect)
                ctx?.strokePath()
                ctx?.fillEllipse(in: circleRect)
                
                let numberFont = UIFont.boldSystemFont(ofSize: 12.0)
                let numberPoint = CGPoint(x: circleRect.origin.x + 2.0, y: circleRect.origin.y)
                number.stringValue.draw(at: numberPoint, withAttributes: [
                    NSAttributedString.Key.font: numberFont
                ])
                
                let compositeImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                loopButton?.setImage(compositeImage, for: .selected)
            }
        } else {
            loopButton?.isSelected = false
        }
    }

    class func displayStringForPlaybackRate(_ rate: PFWPlaybackRate) -> String {
        if Double(rate) == 1.0 {
            return "1x"
        } else {
            return String(format: "%.01f", rate)
        }
    }
}
