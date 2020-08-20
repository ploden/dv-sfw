//
//  TuneCell.m
//  PsalmsForWorship
//
//  Created by PHILIP LODEN on 4/29/10.
//  Copyright 2010 Deo Volente, LLC. All rights reserved.
//

//import Foundation
import UIKit

private let PFWTuneCellAccessoryViewWidth: CGFloat = 70.0
private let PFWTuneCellTitleLabelPadding: CGFloat = 15.0

private func PFWTuneCellLengthRect(_ rect: CGRect) -> CGRect {
    return CGRect(x: 0.0, y: 0.0, width: PFWTuneCellAccessoryViewWidth, height: rect.height)
}

private func PFWTuneCellSwitchRect(_ rect: CGRect, _ switchHeight: CGFloat) -> CGRect {
    let x = rect.maxX - PFWTuneCellAccessoryViewWidth
    let middleY: CGFloat = rect.height / 2.0
    return CGRect(x: x, y: middleY - (switchHeight / 2.0), width: PFWTuneCellAccessoryViewWidth, height: rect.height)
}

class TuneCell: UITableViewCell {
    var number: Int = 0
    private var indexPath: IndexPath?
    var titleLabel: UILabel?
    var lengthLabel: UILabel?
    var onSwitch: UISwitch?
    var isSelectedTune: Bool = false
    
    required init?(coder aDecoder: NSCoder) {
        titleLabel = UILabel()
        lengthLabel = UILabel()
        onSwitch = UISwitch()
        super.init(coder: aDecoder)
    }
    
    /*
    init?(number aNumber: Int, tuneDescription aTuneDescription: PFWTuneDescription?, indexPath anIndexPath: IndexPath?) {
        number = aNumber
        let aSwitch = UISwitch(frame: CGRect.zero)
        aSwitch.transform = aSwitch.transform.scaledBy(x: 0.85, y: 0.85)
        aSwitch.isUserInteractionEnabled = false
        addSubview(aSwitch)
        onSwitch = aSwitch

        lengthLabel = UILabel(frame: CGRect.zero)
        lengthLabel.font = UIFont(name: "Helvetica", size: 16)
        lengthLabel.textColor = UIColor(red: 190.0 / 255, green: 190.0 / 255, blue: 190.0 / 255, alpha: 1)
        lengthLabel.backgroundColor = UIColor.clear
        lengthLabel.text = aTuneDescription?.length
        lengthLabel.textAlignment = .center
        addSubview(lengthLabel)

        titleLabel = UILabel(frame: CGRect.zero)
        titleLabel.font = UIFont(name: "Helvetica", size: 16)
        titleLabel.textColor = UIColor.black
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.adjustsFontSizeToFitWidth = false
        titleLabel.text = aTuneDescription?.title
        addSubview(titleLabel)

        indexPath = anIndexPath

        selectionStyle = .none
    }
     */

    override func layoutSubviews() {
        super.layoutSubviews()

        /*
        let frame = self.frame

        let switchRect = PFWTuneCellSwitchRect(frame, onSwitch.frame.size.height)
        onSwitch.frame = switchRect

        let lengthRect = PFWTuneCellLengthRect(frame)
        lengthLabel.frame = lengthRect

        titleLabel.frame = CGRect(x: lengthRect.maxX + PFWTuneCellTitleLabelPadding, y: 0.0, width: frame.width - lengthRect.width - switchRect.width - PFWTuneCellTitleLabelPadding * 2, height: frame.height)
         */
    }

    func setIsSelectedTune(_ isSelected: Bool) {
        isSelectedTune = isSelected
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // hardcoded YES might cause problems for a TV with more cells
        onSwitch?.setOn(selected, animated: true)
    }
}
