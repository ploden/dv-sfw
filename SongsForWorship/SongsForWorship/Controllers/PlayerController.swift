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
    case tunesNotLoaded, loadingTunes, loadingSelectedTuneForPlayback, loadingTunesDidSucceed, loadingTunesDidFail
}

class PlayerController: NSObject {
    var queue: OperationQueue
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
    private var playerTracks: [PlayerTrack:Any] = [PlayerTrack:Any]()
    
    required init(withSong aSong: Song, delegate: PlayerControllerDelegate, queue: OperationQueue) {
        self.queue = queue
        self.song = aSong
        self.delegate = delegate
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(stopPlaying), name: NSNotification.Name("stop playing"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(_:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        state = .tunesNotLoaded        
    }
    
    func loadTunes() {
        state = .loadingTunes
        
        if
            let app = UIApplication.shared.delegate as? SFWAppDelegate {
            
            let tunesLoaderClass: TunesLoader.Type = {
                if
                    let customClassConfig = app.appConfig.customClasses.first(where: { $0.baseName == String(describing: TunesLoader.self) }),
                    let appName = Bundle.main.appName,
                    let customClass = Bundle.main.classNamed("\(appName).\(customClassConfig.customName)") as? TunesLoader.Type
                {
                    return customClass
                }
                
                return SFWTunesLoader.self
            }()
            
            let mediaTypes: [TuneDescriptionMediaType] = {
                var types = [TuneDescriptionMediaType]()
                if TunesVC.musicLibraryIsEnabled(settings: Settings(fromUserDefaults: .standard)) {
                    types.append(.localMP3)
                }
                if TunesVC.appleMusicIsEnabled(settings: Settings(fromUserDefaults: .standard)) {
                    types.append(.appleMusic)
                }
                types.append(.localMIDI)
                return types
            }()
                
            tunesLoaderClass.loadTunes(forSong: song, withTypes: mediaTypes, completion: { [weak self] finished, someTuneDescriptions, someError in
                if let _ = someError, someTuneDescriptions.count == 0 {
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
                                if let desc = desc as? LocalFileTuneDescription {
                                    let track = PlayerTrack(localFileTuneDescription: desc)
                                    self.playerTracks[track] = desc
                                } else if let desc = desc as? AppleMusicItemTuneDescription {
                                    let track = PlayerTrack(appleMusicItemTuneDescription: desc)
                                    self.playerTracks[track] = desc
                                } else if let desc = desc as? MusicLibraryItemTuneDescription {
                                    let track = PlayerTrack(mediaItem: desc.mediaItem)
                                    self.playerTracks[track] = desc
                                }
                            }
                            let silentDelegate = self.delegate
                            self.delegate = nil
                            self.currentTrack = {
                                if let harmony = self.playerTracks.keys.first(where: { $0.title?.contains("armony") ?? false }) {
                                    return harmony
                                }
                                return self.playerTracks.keys.first
                            }()
                            self.delegate = silentDelegate
                            self.delegate?.playerControllerTracksDidChange(self, tracks: self.tracks())
                        }
                    })
                }
            })
            
        }
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
        player = nil
        
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
                if let item = playerTracks[currentTrack] as? MPMediaItem {
                    return item.playbackDuration
                } else if let item = playerTracks[currentTrack] as? AppleMusicItemTuneDescription {
                    return item.length ?? 0
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
        } else if let desc = playerTracks[track] as? MusicLibraryItemTuneDescription {
            playMediaItem(desc.mediaItem, atTime: time, withDelay: delay, rate: playbackRate)
        } else if let desc = playerTracks[track] as? AppleMusicItemTuneDescription {
            playTuneDescription(desc, atTime: time, withDelay: delay, rate: playbackRate)
        }
    }
    
    func playTuneDescription(_ tuneDescription: TuneDescription, atTime time: TimeInterval, withDelay delay: TimeInterval, rate playbackRate: PFWPlaybackRate) {
        self.playbackRate = playbackRate
        isPaused = false
        
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        
        if let localFileTuneDescription = tuneDescription as? LocalFileTuneDescription {
            switch localFileTuneDescription.mediaType {
            case .localMP3:
                if let player = try? AVAudioPlayer(contentsOf: localFileTuneDescription.url) {
                    player.enableRate = true
                    player.prepareToPlay()
                    player.rate = playbackRate
                    player.currentTime = time
                    player.delegate = self
                    mp3Player = player
                    
                    player.play()
                    delegate?.playbackStateDidChangeForPlayerController(self)
                }
            case .localMIDI:
                if let presetURL = AVMIDIPlayer.songSoundBankUrl(),
                   let player = try? AVMIDIPlayer(withTune: localFileTuneDescription, soundBankURL: presetURL) {
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
            default:
                break
            }
        } else if let appleMusicItemTuneDescription = tuneDescription as? AppleMusicItemTuneDescription {
            self.playbackRate = playbackRate
            isPaused = false
            
            state = .loadingSelectedTuneForPlayback
            
            queue.addOperation { [weak self] in
                if self?.player == nil {
                    self?.player = MPMusicPlayerApplicationController.applicationQueuePlayer
                }
                
                self?.player?.stop()
                
                self?.player?.setQueue(with: [appleMusicItemTuneDescription.appleMusicID])
                
                self?.player?.prepareToPlay(completionHandler: { [weak self] error in
                    if error == nil {
                        OperationQueue.main.addOperation({
                            self?.state = .loadingTunesDidSucceed
                            self?.player?.currentPlaybackRate = playbackRate
                            self?.player?.currentPlaybackTime = time
                            self?.player?.play()
                            if let self = self {
                                self.delegate?.playbackStateDidChangeForPlayerController(self)
                            }
                        })
                    } else {
                        print(error as Any)
                        OperationQueue.main.addOperation({
                            self?.state = .loadingTunesDidFail
                            if let self = self {
                                self.delegate?.playbackStateDidChangeForPlayerController(self)
                            }
                        })
                    }
                })
            }
            
            delegate?.playbackStateDidChangeForPlayerController(self)
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
        //delegate?.playbackStateDidChangeForPlayerController(self)
    }
}
