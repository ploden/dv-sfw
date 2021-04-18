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
