//
//  SelectSongMenuVC.swift
//  SongsForWorship
//
//  Created by Philip Loden on 4/8/21.
//  Copyright © 2021 Deo Volente, LLC. All rights reserved.
//

import UIKit

protocol SelectSongMenuVCDelegate: class {
    func selectSongMenuVC(selectSongMenuVC: SelectSongMenuVC?, didSelectSong selectedSong: Song)
}

class SelectSongMenuVC: UIViewController {
    @IBOutlet weak var stackView: UIStackView?
    weak var delegate: SelectSongMenuVCDelegate?
    var songs: [Song] = [Song]() {
        didSet {
            configure(withSongs: songs)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure(withSongs: songs)
    }

    private func configure(withSongs songs: [Song]) {
        if let stackView = stackView {
            stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            for song in songs {
                let button = UIButton(type: .system)
                button.setTitle(song.number, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .medium)
                button.titleLabel?.theme_tintColor = ThemeColors(
                    defaultLight: UIView().tintColor!,
                    white: UIColor(named: "NavBarBackground")!,
                    night: .white
                ).toHex()
                button.theme_backgroundColor = ThemeColors(defaultLight: .systemBackground, white: .systemBackground, night: UIColor.systemBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))).toHex()
                button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
                
                stackView.insertArrangedSubview(button, at: stackView.arrangedSubviews.count)
            }
        }
    }
    
    // MARK: IBActions
    
    @IBAction func buttonTapped(_ sender: Any) {
        if
            let sender = sender as? UIButton,
            let idx = stackView?.arrangedSubviews.firstIndex(of: sender),
            idx < songs.count
        {
            delegate?.selectSongMenuVC(selectSongMenuVC: self, didSelectSong: songs[idx])
        }
    }
    
    override class var storyboardName: String {
        get {
            return "SongDetail"
        }
    }
}
