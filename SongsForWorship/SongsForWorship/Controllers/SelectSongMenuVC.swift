//
//  SelectSongMenuVC.swift
//  SongsForWorship
//
//  Created by Phil Loden on 4/8/21. Licensed under the MIT license, as follows:
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

protocol SelectSongMenuVCDelegate: AnyObject {
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
                button.theme_backgroundColor = ThemeColors(
                    defaultLight: .systemBackground,
                    white: .systemBackground,
                    night: UIColor.systemBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
                ).toHex()
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
        return "SongDetail"
    }
}
