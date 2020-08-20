//
//  PsalmPreviewViewController.swift
//  PsalmsForWorship
//
//  Created by Jacob Rhoda on 11/1/15.
//  Copyright © 2015 Deo Volente, LLC. All rights reserved.
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
    var song: Song?
    
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

    func setPsalm(_ song: Song?) {
        self.song = song
        configure(with: song)
    }

    func configure(with song: Song?) {
        navigationItem.title = song?.number
        titleLabel?.text = song?.title
        if let verses_line_1 = song?.verses_line_1, let verses_line_2 = song?.verses_line_2 {
            versesLabel?.text = "\(verses_line_1)\n\(verses_line_2)"
        }
        metreLabel?.attributedText = song?.attributedMetreText()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configure(with: song)
    }
}
