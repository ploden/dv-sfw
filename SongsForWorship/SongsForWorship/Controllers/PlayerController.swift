//
//  PlayerController.swift
//  SongsForWorship
//
//  Created by Phil Loden on 12/29/18. Licensed under the MIT license, as follows:
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

import AVFoundation
import MediaPlayer

typealias PFWPlaybackRate = Float

protocol PlayerControllerDelegate: AnyObject, HasAppConfig {
    func playerControllerTracksDidChange(_ playerController: PlayerController, tracks: [PlayerTrack]?)
    func playbackStateDidChangeForPlayerController(_ playerController: PlayerController)
}

enum PlayerControllerState: Int {
    case tunesNotLoaded, loadingTunes, loadingTunesDidSucceed, loadingTunesDidFail
}

class PlayerController: NSObject {
    var timePosition: TimeInterval = 0
    var loadTunesDidFail: Bool = false
    var loopCounter: UInt8 = 0 {
        didSet {
            delegate?.playbackStateDidChangeForPlayerController(self)
        }
    }
    weak var delegate: PlayerControllerDelegate?
    var isPaused: Bool = false
    var state: PlayerControllerState = .tunesNotLoaded
    private var playbackRate: PFWPlaybackRate?
    var currentTrack: PlayerTrack? {
        didSet {
            if currentTrack != oldValue && isPlaying() == false {
                delegate?.playbackStateDidChangeForPlayerController(self)
            }
        }
    }
    private(set) var song: Song
    private var midiPlayer: AVMIDIPlayer?
    private var mp3Player: AVAudioPlayer?
    private var player: MPMusicPlayerController?
    private var playerTracks: [PlayerTrack: Any] = [PlayerTrack: Any]()
    private var tuneInfos: [SongCollectionTuneInfo]

    required init(with song: Song, tuneInfos: [SongCollectionTuneInfo], delegate: PlayerControllerDelegate) {
        self.song = song
        self.tuneInfos = tuneInfos
        self.delegate = delegate
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(stopPlaying), name: NSNotification.Name("stop playing"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(_:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)

        state = .tunesNotLoaded

        let authStatus = MPMediaLibrary.authorizationStatus()

        switch authStatus {
        case .denied, .restricted, .notDetermined:
            break
        case .authorized:
            let numberPredicate = MPMediaPropertyPredicate(value: song.number, forProperty: MPMediaItemPropertyTitle, comparisonType: .contains)

            let titlePredicate = MPMediaPropertyPredicate(value: song.title, forProperty: MPMediaItemPropertyTitle, comparisonType: .contains)

            if
                let numberQueryItems = makeQuery(with: numberPredicate)?.items,
                let titleQueryItems = makeQuery(with: titlePredicate)?.items
            {
                let numberQueryItemsSet = Set<MPMediaItem>(numberQueryItems)
                let  titleQueryItemsSet = Set<MPMediaItem>(titleQueryItems)
                let intersection = titleQueryItemsSet.intersection(numberQueryItemsSet)

                let collection = MPMediaItemCollection(items: Array(intersection))

                for item in collection.items {
                    let track = PlayerTrack(mediaItem: item)
                    playerTracks[track] = item
                }
            }
        default:
            break
        }
    }

    func loadTunes() {
        guard let appConfig = delegate?.appConfig else {
            return
        }

        state = .loadingTunes

        appConfig.tunesLoaderClass.loadTunes(forSong: song, appConfig: appConfig, tuneInfos: tuneInfos, completion: { [weak self] someError, someTuneDescriptions in
            if someError != nil {
                OperationQueue.main.addOperation({
                    self?.state = .loadingTunesDidFail
                    if let self = self {
                        self.delegate?.playerControllerTracksDidChange(self, tracks: self.tracks())
                    }
                })
            } else {
                OperationQueue.main.addOperation({
                    if let self = self {
                        self.state = .loadingTunesDidSucceed
                        for desc in someTuneDescriptions {
                            let track = PlayerTrack(tuneDescription: desc)
                            self.playerTracks[track] = desc
                        }
                        let silentDelegate = self.delegate
                        self.delegate = nil
                        self.currentTrack = self.playerTracks.keys.first
                        self.delegate = silentDelegate
                        self.delegate?.playerControllerTracksDidChange(self, tracks: self.tracks())
                    }
                })
            }
        })

    }

    func makeQuery(with predicate: MPMediaPropertyPredicate?) -> MPMediaQuery? {
        let query = MPMediaQuery.songs()

        //  [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:@"Crown & Covenant" forProperty:MPMediaItemPropertyArtist comparisonType:MPMediaPredicateComparisonEqualTo]];
        if let predicate = predicate {
            query.addFilterPredicate(predicate)
        }
        query.groupingType = .album

        return query
    }

    func isPlaying() -> Bool {
        if let midiPlayer = midiPlayer {
            return midiPlayer.isPlaying
        } else if let mp3Player = mp3Player {
            return mp3Player.isPlaying
        } else if let player = player {
            return player.playbackState == .playing
        }
        return false
    }

    func restartTrack() {
        midiPlayer?.currentPosition = 0
        mp3Player?.currentTime = 0
        player?.skipToBeginning()
    }

    func changePlaybackRate(_ aPlaybackRate: PFWPlaybackRate) {
        playbackRate = aPlaybackRate

        if
            isPlaying(),
            let playbackRate = playbackRate,
            let currentTrack = currentTrack
        {
            let tmpLoopCounter = loopCounter
            playTrack(currentTrack, atTime: currentPosition(), withDelay: 0.0, rate: playbackRate)
            loopCounter = tmpLoopCounter
        }
    }

    @objc func stopPlaying() {
        isPaused = false
        loopCounter = 0

        midiPlayer?.stop()
        midiPlayer = nil
        mp3Player?.stop()
        mp3Player = nil
        player?.stop()

        delegate?.playbackStateDidChangeForPlayerController(self)
    }

    func pause() {
        isPaused = true
        midiPlayer?.stop()
        mp3Player?.pause()
        player?.pause()
        delegate?.playbackStateDidChangeForPlayerController(self)
    }

    func resume() {
        if !isPaused {
            return
        }

        if let currentTrack = currentTrack {
            if currentTrack.trackType == PlayerTrackType.tune {
                midiPlayer?.play(nil)
                mp3Player?.play()
            } else if currentTrack.trackType == PlayerTrackType.recording {
                player?.play()
            }

            isPaused = false
            delegate?.playbackStateDidChangeForPlayerController(self)
        }
    }

    func currentPosition() -> TimeInterval {
        if let currentTrack = currentTrack {
            if currentTrack.trackType == PlayerTrackType.tune {
                return midiPlayer?.currentPosition ?? mp3Player?.currentTime ?? 0.0
            } else if currentTrack.trackType == PlayerTrackType.recording {
                return player?.currentPlaybackTime ?? 0.0
            }
        }
        return 0.0
    }

    func duration() -> TimeInterval {
        if let currentTrack = currentTrack {
            if currentTrack.trackType == PlayerTrackType.tune {
                return midiPlayer?.duration ?? mp3Player?.duration ?? 0.0
            } else if currentTrack.trackType == PlayerTrackType.recording {
                let obj = playerTracks[currentTrack]

                if let item = obj as? MPMediaItem {
                    return item.playbackDuration
                }
            }
        }
        return 0.0
    }

    func tunePlayerDidFinishPlaying() {
        delegate?.playbackStateDidChangeForPlayerController(self)

        if isPaused {
            return
        }

        if loopCounter > 0 {
            loopCounter -= 1
        }

        if loopCounter > 0 {
            if
                let currentTrack = currentTrack,
                let playbackRate = playbackRate
            {
                playTrack(currentTrack, atTime: 0.0, withDelay: 0.75, rate: playbackRate)
            }
        } else {
            // we're done or paused.
            timePosition = 0
            stopPlaying()
        }

        delegate?.playbackStateDidChangeForPlayerController(self)
    }

    func tracks() -> [PlayerTrack] {
        var tmp = [PlayerTrack]()

        for key in playerTracks.keys {
            tmp.append(key)
        }

        return tmp
    }

    func playTrack(_ track: PlayerTrack, atTime time: TimeInterval, withDelay delay: TimeInterval, rate playbackRate: PFWPlaybackRate) {
        var wasPlaying = false

        if isPlaying() {
            wasPlaying = true
            stopPlaying()
        }

        currentTrack = track

        if let desc = playerTracks[track] as? LocalFileTuneDescription {
            if wasPlaying {
                /*
                 For reasons that I do not understand, stopping one track and then immediately starting
                 another does not work.
                 */
                OperationQueue.main.addOperation({ [weak self] in
                    self?.playTuneDescription(desc, atTime: time, withDelay: delay, rate: playbackRate)
                })
            } else {
                playTuneDescription(desc, atTime: time, withDelay: delay, rate: playbackRate)
            }
        } else if let item = playerTracks[track] as? MPMediaItem {
            playMediaItem(item, atTime: time, withDelay: delay, rate: playbackRate)
        }
    }

    func playTuneDescription(_ tuneDescription: LocalFileTuneDescription, atTime time: TimeInterval, withDelay delay: TimeInterval, rate playbackRate: PFWPlaybackRate) {
        self.playbackRate = playbackRate
        isPaused = false

        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        } catch {
            print("There was an error setting the session category: \(error)")
        }

        do {
            switch tuneDescription.mediaType {
            case .mp3:
                let player = try AVAudioPlayer(contentsOf: tuneDescription.url)
                player.enableRate = true
                player.prepareToPlay()
                player.rate = playbackRate
                player.currentTime = time
                player.delegate = self
                mp3Player = player

                player.play()
                delegate?.playbackStateDidChangeForPlayerController(self)
            case .midi, .localMidi:
                if let presetURL = AVMIDIPlayer.songSoundBankUrl() {
                    let player = try AVMIDIPlayer(withTune: tuneDescription, soundBankURL: presetURL)
                    player.rate = playbackRate
                    player.currentPosition = time
                    midiPlayer = player

                    player.play({ [weak self] in
                        OperationQueue.main.addOperation({
                            self?.tunePlayerDidFinishPlaying()
                        })
                    })
                    delegate?.playbackStateDidChangeForPlayerController(self)
                }
            }
        } catch {
            print("There was an error starting playback! \(error)")
        }
    }

    func playMediaItem(_ mediaItem: MPMediaItem?, atTime time: TimeInterval, withDelay delay: TimeInterval, rate playbackRate: PFWPlaybackRate) {
        self.playbackRate = playbackRate
        isPaused = false

        if player == nil {
            player = MPMusicPlayerApplicationController.applicationQueuePlayer
        }

        let col = MPMediaItemCollection(items: [mediaItem].compactMap { $0 })
        player?.setQueue(with: col)

        player?.prepareToPlay(completionHandler: { [weak self] error in
            if error == nil {
                OperationQueue.main.addOperation({
                    self?.player?.play()
                    if let self = self {
                        self.delegate?.playbackStateDidChangeForPlayerController(self)
                    }
                })
            } else {
                print(error as Any)
            }
        })

        delegate?.playbackStateDidChangeForPlayerController(self)
    }

    @objc func playerItemDidReachEnd(_ notification: Notification?) {
        tunePlayerDidFinishPlaying()
    }
}

extension PlayerController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        tunePlayerDidFinishPlaying()
    }
}
