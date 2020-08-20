//  TunesViewController.m
//  PsalmsForWorship
//
//  Created by PHILIP LODEN on 4/28/10.
//  Copyright 2010 Deo Volente, LLC. All rights reserved.
//

import MediaPlayer

enum PFWTunesVCTableViewSection : Int {
    case _Tune = 0
    case _Recording = 1
    case _Count = 2
}

class TunesVC: UIViewController, UITableViewDataSource, UITableViewDelegate, AVAudioPlayerDelegate, PlayerControlsViewDelegate, PlayerControllerDelegate, HasSongsManager, PsalmObserver {
    override class var storyboardName: String {
        get {
            return "SongDetail"
        }
    }
    private var isObservingcurrentSong = false
    
    @IBOutlet weak var playerControlsView: PlayerControlsView?
    
    @IBOutlet weak var volumeControl: MPVolumeView? {
        didSet {
            volumeControl?.showsRouteButton = false
        }
    }
    private var progressUpdateTimer: Timer?
    private var playerController: PlayerController = PlayerController() {
        didSet {
        }
    }
    private var tuneTracks: [PlayerTrack]?
    private var recordingTracks: [PlayerTrack]?
    var songsManager: SongsManager?
    var loadedPsalmNumber: String?
    @IBOutlet weak var tunesTableView: UITableView?
    @IBOutlet weak var tuneProgressBar: UIProgressView?
    var lastSelectedCell: IndexPath?
    var lastLoadedPsalmNumber: String?
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if var textAttributes = navigationController?.navigationBar.titleTextAttributes {
            textAttributes[NSAttributedString.Key.font] = UIFont.systemFont(ofSize: 20.0)
            textAttributes[NSAttributedString.Key.foregroundColor] = UIColor.white
            navigationController?.navigationBar.titleTextAttributes = textAttributes
        }
        
        if let songsManager = songsManager {
            songsManager.addObserver(forcurrentSong: self)
            isObservingcurrentSong = true
        }
        
        playerControlsView?.delegate = self
        
        volumeControl?.showsRouteButton = false
        
        let currentSong = songsManager?.currentSong
        change(currentSong)
        
        configureSelectedTrackTitleLabel()
        
        let playTrackClassStr = "PlayTrackTVCell"
        tunesTableView?.register(UINib(nibName: playTrackClassStr, bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: playTrackClassStr)
        
        let playRecordingClassStr = "PlayRecordingTVCell"
        tunesTableView?.register(UINib(nibName: playRecordingClassStr, bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: playRecordingClassStr)
        
        let noRecordingsFoundClassStr = "NoRecordingsFoundTVCell"
        tunesTableView?.register(UINib(nibName: noRecordingsFoundClassStr, bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: noRecordingsFoundClassStr)
        
        let enableRecordingsClassStr = "EnableRecordingsTVCell"
        tunesTableView?.register(UINib(nibName: enableRecordingsClassStr, bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: enableRecordingsClassStr)
        
        let recordingsDisabledClassStr = "RecordingsDisabledTVCell"
        tunesTableView?.register(UINib(nibName: recordingsDisabledClassStr, bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: recordingsDisabledClassStr)
        
        playerController.delegate = self
        playerController.song = currentSong
        playerController.collection = songsManager?.currentCollection
        
        tunesTableView?.register(UINib(nibName: "TunesHeaderView", bundle: Helper.songsForWorshipBundle()), forHeaderFooterViewReuseIdentifier: "TunesHeaderView")
        
        tunesTableView?.estimatedRowHeight = 44.0
        tunesTableView?.rowHeight = UITableView.automaticDimension
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    func change(_ currentSong: Song?) {
        if (lastLoadedPsalmNumber == currentSong?.number) {
            // do nothing?
        } else {
            playerControlsView?.loopButton?.isSelected = false
            playerControlsView?.playButton?.isSelected = false
            tuneTracks = nil
            recordingTracks = nil
            playerController.song = currentSong
            playerController.collection = songsManager?.currentCollection
            tunesTableView?.reloadData()
            lastLoadedPsalmNumber = currentSong?.number
        }
    }
    
    func tunesDidLoad(_ aNotification: Notification?) {
        tunesTableView?.reloadData()
    }
    
    func timePosition() -> TimeInterval {
        return playerController.timePosition
    }
    
    // MARK: - NSObject
    deinit {
        if isObservingcurrentSong {
            songsManager?.removeObserver(forcurrentSong: self)
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - IBActions
    @IBAction func loopButtonPressed() {
        playerControlsView?.loopButton?.isSelected = !(playerControlsView?.loopButton?.isSelected)!
        
        if playerControlsView?.loopButton?.isSelected != nil {
            playerController.loopCounter = Int8(songsManager?.currentSong?.stanzas.count ?? 0)
            playerControlsView?.configureLoopButtonWithNumber(NSNumber(value: playerController.loopCounter))
        } else {
            playerController.loopCounter = 0
        }
    }
    
    @IBAction func playButtonPressed() {
        if tuneTracks?.count == 0 {
            return
        }
        
        if isPlaying() {
            // pause
            pausePlayback()
        } else if playerController.isPaused {
            // resume
            resumePlayback()
        } else {
            // begin
            if
                let currentTrack = playerController.currentTrack,
                let playerControlsView = playerControlsView
            {
                playerController.playTrack(currentTrack, atTime: 0.0, withDelay: 0.0, rate: playerControlsView.currentPlaybackRate())
            }
        }
    }
    
    @IBAction func prevButtonPressed() {
        if isPlaying() {
            restartTrack()
        }
    }
    
    @IBAction func nextButtonPressed() {
        return // do nothing. should we do something?
    }
    
    func playbackRateDidChange() {
        if isPlaying() {
            if let playerControlsView = playerControlsView {
                playerController.changePlaybackRate(playerControlsView.currentPlaybackRate())
            }
        }
    }
    
    class func playbackRateClosest(toRate rate: CGFloat) -> PFWPlaybackRate {
        var idxOfClosest: size_t = 0
        var dif = CGFloat(PFWPlaybackRates[Int(PFWNumPlaybackRates) - 1])
        
        for idx in 0..<Int(PFWNumPlaybackRates) {
            let currentDif = CGFloat(abs(Float(rate - CGFloat(PFWPlaybackRates[idx]))))
            
            if currentDif < dif {
                idxOfClosest = idx
                dif = currentDif
            }
        }
        
        return PFWPlaybackRates[idxOfClosest]
    }
    
    // MARK: - UITableView
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tunesTableView?.dequeueReusableHeaderFooterView(withIdentifier: "TunesHeaderView") as? TunesHeaderView
        
        header?.headerTitleLabel?.text = {
            if section == 0 {
                return "Tunes for Sheet Music"
            } else {
                return "Recordings"
            }
        }()
        
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 54.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return PFWTunesVCTableViewSection._Count.rawValue
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case PFWTunesVCTableViewSection._Tune.rawValue:
            let num_rows = tuneTracks?.count ?? 0
            return max(1, num_rows)
        case PFWTunesVCTableViewSection._Recording.rawValue:
            let num_rows = recordingTracks?.count ?? 0
            return max(1, num_rows)
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        switch indexPath.section {
        case PFWTunesVCTableViewSection._Tune.rawValue:
            if tuneTracks?.count == 0 {
                cell = headerCell(for: tableView)
            } else {
                let playTrackTVCell = tableView.dequeueReusableCell(withIdentifier: "PlayTrackTVCell") as? PlayTrackTVCell
                
                if indexPath.row < (tuneTracks?.count ?? 0) {
                    playTrackTVCell?.trackTitleLabel?.text = tuneTracks?[indexPath.row].title
                }
                
                cell = playTrackTVCell
            }
        case PFWTunesVCTableViewSection._Recording.rawValue:
            if let recordingTracks = recordingTracks {
                if recordingTracks.count == 0 {
                    cell = recordingHeaderCell(for: tableView)
                } else {
                    let playRecordingTVCell = tableView.dequeueReusableCell(withIdentifier: "PlayRecordingTVCell") as? PlayRecordingTVCell
                    
                    if indexPath.row < recordingTracks.count {
                        let track = recordingTracks[indexPath.row]
                        playRecordingTVCell?.configureWithAlbumTitle(track.albumTitle, albumArtwork: track.albumArtwork, trackTitle: track.title, artist: track.artist)
                    }
                    
                    cell = playRecordingTVCell
                }
            } else {
                cell = recordingHeaderCell(for: tableView)
            }
        default:
            break
        }
        
        if cell == nil {
            cell = UITableViewCell()
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case PFWTunesVCTableViewSection._Tune.rawValue:
            if
                let playerControlsView = playerControlsView,
                let tuneTracks = tuneTracks,
                indexPath.row < tuneTracks.count
            {
                let track = tuneTracks[indexPath.row]
                playerController.playTrack(track, atTime: 0.0, withDelay: 0.0, rate: playerControlsView.currentPlaybackRate())
            }
        case PFWTunesVCTableViewSection._Recording.rawValue:
            if
                let playerControlsView = playerControlsView,
                let recordingTracks = recordingTracks,
                indexPath.row < recordingTracks.count
            {
                let track = recordingTracks[indexPath.row]
                playerController.playTrack(track, atTime: 0.0, withDelay: 0.0, rate: playerControlsView.currentPlaybackRate())
            } else {
                let authStatus = MPMediaLibrary.authorizationStatus()
                
                switch authStatus {
                case .denied:
                    break
                case .restricted, .notDetermined:
                    weak var weakSelf = self
                    
                    MPMediaLibrary.requestAuthorization({ authorizationStatus in
                        OperationQueue.main.addOperation({
                            if authorizationStatus == .authorized {
                                weakSelf?.playerController.song = weakSelf?.songsManager?.currentSong
                                weakSelf?.playerController.collection = weakSelf?.songsManager?.currentCollection
                            } else {
                                // user did not authorize
                                weakSelf?.tunesTableView?.reloadData()
                            }
                        })
                    })
                case .authorized:
                    fallthrough
                default:
                    break
                }
            }
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Helper methods
    func configureSelectedTrackTitleLabel() {
        playerControlsView?.trackTitleLabel?.text = {
            if let currentTrack = self.playerController.currentTrack {
                if currentTrack.trackType == .tune {
                    return currentTrack.title
                } else if currentTrack.trackType == .recording {
                    return (currentTrack.albumTitle?.count ?? 0) > 0 ? currentTrack.albumTitle : currentTrack.title
                }
            }
            return ""
        }()
    }
    
    static let headerCellCellIdentifier = "Cell"
    
    func headerCell(for tableView: UITableView?) -> UITableViewCell {
        
        var cell = tableView?.dequeueReusableCell(withIdentifier: TunesVC.headerCellCellIdentifier)
        
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: TunesVC.headerCellCellIdentifier)
        }
        
        if tuneTracks?.count == 0 {
            if playerController.loadTunesDidFail {
                cell?.textLabel?.text = "No Tunes Found"
            } else if songsManager?.currentSong?.isTuneCopyrighted == true {
                cell?.textLabel?.text = "No Tunes available for this psalm."
            } else {
                cell?.textLabel?.text = "Loading..."
            }
        } else {
            cell?.textLabel?.text = "Tunes"
        }
        cell?.textLabel?.textAlignment = .center
        cell?.textLabel?.font = UIFont(name: "Arial", size: 18.0)
        cell?.textLabel?.textColor = UIColor.label
        cell?.selectionStyle = .none
        
        return cell!
    }
    
    func recordingHeaderCell(for tableView: UITableView?) -> UITableViewCell {
        if recordingTracks?.count == 0 {
            let authStatus = MPMediaLibrary.authorizationStatus()
            
            switch authStatus {
            case .denied:
                let cell = tableView?.dequeueReusableCell(withIdentifier: "RecordingsDisabledTVCell")
                return cell!
            case .restricted, .notDetermined:
                let cell = tableView?.dequeueReusableCell(withIdentifier: "EnableRecordingsTVCell")
                return cell!
            case .authorized:
                let cell = tableView?.dequeueReusableCell(withIdentifier: "NoRecordingsFoundTVCell")
                return cell!
            default:
                break
            }
        }
        
        return UITableViewCell()
    }
    
    class func titleFromPartAbbreviation(_ abbreviation: String?) -> String? {
        if (abbreviation == "a") {
            return "Alto"
        } else if (abbreviation == "b") {
            return "Bass"
        } else if (abbreviation == "s") {
            return "Soprano"
        } else if (abbreviation == "t") {
            return "Tenor"
        }
        return nil
    }
    
    class func titleFromNumber(_ number: Int) -> String {
        var title: String?
        switch number {
        case 0:
            title = "Four-Part Harmony"
        case 1:
            title = "Soprano"
        case 2:
            title = "Bass"
        case 3:
            title = "Alto"
        case 4:
            title = "Tenor"
        default:
            title = "Tune"
        }
        return title ?? ""
    }
    
    func songDidChange(_ notification: Notification) {
        if
            let object = notification.object as? SongsManager,
            object == songsManager
        {
            stopPlaying()
            let newPsalm = object.currentSong
            self.change(newPsalm)
        }
    }
    
    // MARK: - MIDI
    func isPlaying() -> Bool {
        return playerController.isPlaying()
    }
    
    func pausePlayback() {
        playerController.pause()
    }
    
    func resumePlayback() {
        playerController.resume()
    }
    
    func restartTrack() {
        playerController.restartTrack()
    }
    
    func stopPlaying() {
        playerController.stopPlaying()
    }
    
    func initiateProgressUpdateTimer() {
        progressUpdateTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(progressTimerUpdate), userInfo: nil, repeats: true)
    }
    
    func invalidateProgressUpdateTimer() {
        progressUpdateTimer?.invalidate()
        progressUpdateTimer = nil
    }
    
    func updateProgressView() {
        if playerController.isPlaying() || playerController.isPaused {
            let duration = playerController.duration()
            let currentPos = playerController.currentPosition()
            
            let progressPercent = Float(currentPos / duration)
            
            tuneProgressBar?.progress = progressPercent
        } else {
            tuneProgressBar?.progress = 0.0
        }
    }
    
    @objc func progressTimerUpdate() {
        updateProgressView()
    }
    
    // MARK: - PFWPlayerControllerDelegate
    func playerControllerTracksDidChange(_ playerController: PlayerController?, tracks: [PlayerTrack]?) {
        tuneTracks = nil
        recordingTracks = nil
        
        let tunes = tracks?.filter { $0.trackType == .tune }
        
        var newTunes: [PlayerTrack] = []
        
        let titles = ["harmony", "soprano", "tenor", "alto", "bass"]
        
        for title in titles {
            let matches = tunes?.filter {
                if let _ = $0.title?.range(of: title, options: .caseInsensitive) {
                    return true
                }
                return false
            }
            
            if let firstObject = matches?.first {
                newTunes.append(firstObject)
            }
        }
        
        tuneTracks = newTunes
        
        recordingTracks = tracks?.filter { $0.trackType == .recording }
        
        if self.playerController.currentTrack == nil {
            self.playerController.currentTrack = tuneTracks?.first
        }
        
        updateProgressView()
        tunesTableView?.reloadData()
    }
    
    func playbackStateDidChangeForPlayerController(_ playerController: PlayerController?) {
        updateProgressView()
        
        if self.playerController.isPlaying() {
            playerControlsView?.playButton?.isSelected = true
            
            if progressUpdateTimer == nil {
                initiateProgressUpdateTimer()
            }
        } else {
            invalidateProgressUpdateTimer()
            playerControlsView?.playButton?.isSelected = false
        }
        
        if let playerController = playerController {
            playerControlsView?.configureLoopButtonWithNumber(NSNumber(value: playerController.loopCounter))
        }
        
        configureSelectedTrackTitleLabel()
        
        if self.playerController.loopCounter > 0 {
            playerControlsView?.loopButton?.isSelected = true
            if let playerController = playerController {
                playerControlsView?.configureLoopButtonWithNumber(NSNumber(value: playerController.loopCounter))
            }
        } else {
            playerControlsView?.loopButton?.isSelected = false
        }
    }
}
