//
//  TuneCell.m
//  SongsForWorship
//
//  Created by Phil Loden on 4/29/10. Licensed under the MIT license, as follows:
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

import UIKit

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

    func setIsSelectedTune(_ isSelected: Bool) {
        isSelectedTune = isSelected
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // hardcoded YES might cause problems for a TV with more cells
        onSwitch?.setOn(selected, animated: true)
    }
}
