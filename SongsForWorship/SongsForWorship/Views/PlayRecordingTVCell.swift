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
                if
                    let settings = Settings(fromUserDefaults: .standard),
                    settings.shouldUseSystemFonts
                {
                    return UIFont.preferredFont(forTextStyle: .title3)
                }
                return UIFont.systemFont(ofSize: 14.0, weight: .light)
            }()
        }
    }
    @IBOutlet private weak var artworkImageView: UIImageView?
    @IBOutlet private weak var trackTitleLabel: UILabel? {
        didSet {
            trackTitleLabel?.font = {
                if
                    let settings = Settings(fromUserDefaults: .standard),
                    settings.shouldUseSystemFonts
                {
                    return UIFont.preferredFont(forTextStyle: .title2)
                }
                return UIFont.systemFont(ofSize: 14.0, weight: .light)
            }()
        }
    }
    @IBOutlet private weak var artistLabel: UILabel? {
        didSet {
            artistLabel?.font = {
                if
                    let settings = Settings(fromUserDefaults: .standard),
                    settings.shouldUseSystemFonts
                {
                    return UIFont.preferredFont(forTextStyle: .title3)
                }
                return UIFont.systemFont(ofSize: 14.0, weight: .light)
            }()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        artworkImageView?.layer.cornerRadius = 2.0
    }

    func configureWithAlbumTitle(_ albumTitle: String?, albumArtwork: UIImage?, trackTitle: String?, artist: String?) {
        if (albumTitle?.count ?? 0) > 0 {
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
