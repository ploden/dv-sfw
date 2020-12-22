//
//  PlayRecordingTVCell.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 6/17/18.
//  Copyright © 2018 Deo Volente, LLC. All rights reserved.
//

import UIKit

class PlayRecordingTVCell: UITableViewCell {
    @IBOutlet private weak var albumTitleLabel: UILabel? {
        didSet {
            albumTitleLabel?.font = {
                if let app = UIApplication.shared.delegate as? PsalterAppDelegate {
                    if app.settings.shouldUseSystemFonts {
                        return UIFont.preferredFont(forTextStyle: .title3)
                    }
                }
                return UIFont.systemFont(ofSize: 14.0, weight: .light)
            }()
        }
    }
    @IBOutlet private weak var artworkImageView: UIImageView?
    @IBOutlet private weak var trackTitleLabel: UILabel? {
        didSet {
            trackTitleLabel?.font = {
                if let app = UIApplication.shared.delegate as? PsalterAppDelegate {
                    if app.settings.shouldUseSystemFonts {
                        return UIFont.preferredFont(forTextStyle: .title2)
                    }
                }
                return UIFont.systemFont(ofSize: 14.0, weight: .light)
            }()
        }
    }
    @IBOutlet private weak var artistLabel: UILabel? {
        didSet {
            artistLabel?.font = {
                if let app = UIApplication.shared.delegate as? PsalterAppDelegate {
                    if app.settings.shouldUseSystemFonts {
                        return UIFont.preferredFont(forTextStyle: .title3)
                    }
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
