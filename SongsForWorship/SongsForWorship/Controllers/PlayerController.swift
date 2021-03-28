//
//  PlayerController.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 12/29/18.
//  Copyright © 2018 Deo Volente, LLC. All rights reserved.
//

import AVFoundation
import MediaPlayer

typealias PFWPlaybackRate = Float

protocol PlayerControllerDelegate: class {
    func playerControllerTracksDidChange(_ playerController: PlayerController, tracks: [PlayerTrack]?)
    func playbackStateDidChangeForPlayerController(_ playerController: PlayerController)
}

enum PlayerControllerState: Int {
    case tunesNotLoaded, loadingTunes, loadingTunesDidSucceed, loadingTunesDidFail
}

class PlayerController: NSObject {
    var timePosition: TimeInterval = 0
    var loadTunesDidFail: Bool = false
    var loopCounter: Int8 = 0 {
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
    var collection: SongCollection
    private(set) var song: Song
    private var midiPlayer: AVMIDIPlayer?
    private var mp3Player: AVAudioPlayer?
    private var player: MPMusicPlayerController?
    private var playerTracks: [PlayerTrack:Any] = [PlayerTrack:Any]()
    
    required init(withSong aSong: Song, aCollection: SongCollection, delegate: PlayerControllerDelegate) {
        self.song = aSong
        self.collection = aCollection
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
        state = .loadingTunes
        BaseTunesLoader.loadTunes(forSong: song, collection: collection, completion: { [weak self] someError, someTuneDescriptions in
            if let _ = someError {
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
            playTrack(currentTrack, atTime: currentPosition(), withDelay: 0.0, rate: playbackRate)
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
                
                if (obj is MPMediaItem) {
                    let item = obj as? MPMediaItem
                    return item?.playbackDuration ?? 0.0
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
        
        loopCounter = max(0, loopCounter - 1)
        
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
        
        if let desc = playerTracks[track] as? TuneDescription {
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
    
    func playTuneDescription(_ tuneDescription: TuneDescription, atTime time: TimeInterval, withDelay delay: TimeInterval, rate playbackRate: PFWPlaybackRate) {
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
            case .midi:
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
                print(error)
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
        delegate?.playbackStateDidChangeForPlayerController(self)
    }
}
