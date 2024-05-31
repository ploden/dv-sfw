//
//  PlayRecordingTVCell.swift
//  SongsForWorship
//
//  Created by Phil Loden on 6/17/18. Licensed under the MIT license, as follows:
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

class PlayRecordingTVCell: UITableViewCell {
    @IBOutlet private weak var albumTitleLabel: UILabel? {
        didSet {
            albumTitleLabel?.font = {
                let preferred = UIFont.preferredFont(forTextStyle: .body)
                return UIFont.systemFont(ofSize: preferred.pointSize, weight: .light)
            }()
        }
    }
    @IBOutlet private weak var artworkImageView: UIImageView?
    @IBOutlet private weak var shadowView: UIView?
    @IBOutlet private weak var trackTitleLabel: UILabel? {
        didSet {
            trackTitleLabel?.font = {
                let preferred = UIFont.preferredFont(forTextStyle: .body)
                return UIFont.systemFont(ofSize: preferred.pointSize, weight: .light)
            }()
        }
    }
    @IBOutlet private weak var artistLabel: UILabel? {
        didSet {
            artistLabel?.font = {
                let preferred = UIFont.preferredFont(forTextStyle: .body)
                return UIFont.systemFont(ofSize: preferred.pointSize, weight: .light)
            }()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        if
            let artworkImageView = artworkImageView,
            let shadowView = shadowView
        {
            artworkImageView.layer.cornerRadius = 4.0
            shadowView.layer.cornerRadius = artworkImageView.layer.cornerRadius
            shadowView.layer.shadowRadius = shadowView.layer.cornerRadius
            shadowView.layer.shadowOpacity = 0.8
            shadowView.layer.shadowColor = UIColor.black.cgColor
            shadowView.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        }
    }

    func configureWithAlbumTitle(_ albumTitle: String?, albumArtwork: UIImage?, trackTitle: String?, artist: String?) {
        if let albumTitle = albumTitle, albumTitle.count > 0 {
            albumTitleLabel?.isHidden = false
            albumTitleLabel?.text = albumTitle

            trackTitleLabel?.isHidden = true
            artistLabel?.isHidden = true
        } else {
            trackTitleLabel?.isHidden = false
            trackTitleLabel?.text = trackTitle
            artistLabel?.isHidden = false
            artistLabel?.text = artist

            albumTitleLabel?.isHidden = true
        }

        artworkImageView?.image = albumArtwork ?? UIImage(named: "album_placeholder", in: Helper.songsForWorshipBundle(), with: .none)        
    }
}
