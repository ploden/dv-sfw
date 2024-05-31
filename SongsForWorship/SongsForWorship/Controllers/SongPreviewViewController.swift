//
//  PsalmPreviewViewController.swift
//  SongsForWorship
//
//  Created by Jacob Rhoda on 11/1/15. Licensed under the MIT license, as follows:
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

class SongPreviewViewController: UIViewController {
    @IBOutlet weak var navBar: UINavigationBar? {
        didSet {
            navBar?.items = [self.navigationItem]
        }
    }
    @IBOutlet weak var metreLabel: UILabel?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var versesLabel: UILabel?
    @IBOutlet weak var copyrightLabel: UILabel?
    var song: (Song)?

    init(withPsalm song: Song) {
        super.init(nibName: nil, bundle: Helper.songsForWorshipBundle())
        self.song = song
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func nibName() -> String? {
        return "PsalmPreviewViewController"
    }

    func setPsalm(_ song: (Song)?) {
        self.song = song
        configure(with: song)
    }

    func configure(with song: (Song)?) {
        navigationItem.title = song?.number
        titleLabel?.text = song?.title

        /*
        if let versesLine1 = song?.versesLine1, let versesLine2 = song?.versesLine2 {
            versesLabel?.text = "\(versesLine1)\n\(versesLine2)"
        }
         */
        
        metreLabel?.attributedText = song?.attributedMetreText()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configure(with: song)
    }
}
