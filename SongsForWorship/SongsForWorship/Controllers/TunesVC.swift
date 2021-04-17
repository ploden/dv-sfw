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

struct TunesVCItem {
    let indexPath: IndexPath
    let cellID: String
    let track: PlayerTrack?
}

open class TunesVC: UIViewController, UITableViewDataSource, UITableViewDelegate, AVAudioPlayerDelegate, PlayerControlsViewDelegate, PlayerControllerDelegate, HasSongsManager {
    enum ImageNames: String {
        case pause = "pause.fill", play = "play.fill", repeatTrack = "repeat" 
    }
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
    lazy var playerController: PlayerController? = {
        if
            let songsManager = songsManager,
            let currentSong = songsManager.currentSong
        {
            return PlayerController(withSong: currentSong, delegate: self)
        }
        return nil
    }() {
        didSet {
            playerController?.delegate = self
            if isViewLoaded {
                configurePlayerControlsView()
            }
        }
    }
    open var tuneTracks: [PlayerTrack]?
    private var recordingTracks: [PlayerTrack]?
    var songsManager: SongsManager?
    var loadedPsalmNumber: String?
    @IBOutlet weak var tunesTableView: UITableView? {
        didSet {
            if let tunesTableView = tunesTableView {
                tunesTableView.separatorStyle = {
                    if hasTableViewHeaders(tableView: tunesTableView) {
                        return UITableViewCell.SeparatorStyle.singleLine
                    } else {
                        return UITableViewCell.SeparatorStyle.none
                    }
                }()
            }
        }
    }
    @IBOutlet weak var tuneProgressBar: UIProgressView?
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint?
    var lastSelectedCell: IndexPath?
    lazy var shouldShowAdditionalTunes: Bool = {
        return (UIApplication.shared.delegate as? PsalterAppDelegate)?.appConfig.shouldShowAdditionalTunes ?? false
    }()
    lazy var tuneRecordings: Bool = {
        return (UIApplication.shared.delegate as? PsalterAppDelegate)?.appConfig.tuneRecordings ?? false
    }()
    var items: [TunesVCItem] = [TunesVCItem]()
    
    // MARK: - UIViewController
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        playerControlsView?.delegate = self
        
        volumeControl?.showsRouteButton = false
        
        let currentSong = songsManager?.currentSong
        change(currentSong)
                
        let playTrackClassStr = "PlayTrackTVCell"
        tunesTableView?.register(UINib(nibName: playTrackClassStr, bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: playTrackClassStr)
        
        let playRecordingClassStr = "PlayRecordingTVCell"
        tunesTableView?.register(UINib(nibName: playRecordingClassStr, bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: playRecordingClassStr)
        
        let noRecordingsFoundClassStr = "NoRecordingsFoundTVCell"
        tunesTableView?.register(UINib(nibName: noRecordingsFoundClassStr, bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: noRecordingsFoundClassStr)
        
        tunesTableView?.register(UINib(nibName: String(describing: EnableMusicLibraryTVCell.self), bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: String(describing: EnableMusicLibraryTVCell.self))
        tunesTableView?.register(UINib(nibName: String(describing: EnableAppleMusicTVCell.self), bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: String(describing: EnableAppleMusicTVCell.self))

        let recordingsDisabledClassStr = "RecordingsDisabledTVCell"
        tunesTableView?.register(UINib(nibName: recordingsDisabledClassStr, bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: recordingsDisabledClassStr)
        
        tunesTableView?.register(UINib(nibName: "TunesHeaderView", bundle: Helper.songsForWorshipBundle()), forHeaderFooterViewReuseIdentifier: "TunesHeaderView")
        
        tunesTableView?.estimatedRowHeight = 44.0
        tunesTableView?.rowHeight = UITableView.automaticDimension
        
        if shouldShowAdditionalTunes == false {
            tableViewHeightConstraint?.constant = 0.0
            tableViewHeightConstraint?.priority = .required
        } else {
            tableViewHeightConstraint?.constant = 88.0
            tableViewHeightConstraint?.priority = .required
        }
        
        configurePlayerControlsView()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configurePlayerControlsView()
        
        if
            let playerController = playerController,
            playerController.song == songsManager?.currentSong,
            playerController.state == .loadingTunesDidSucceed
        {
            items = TunesVC.calculateItems(forPlayerTracks: playerController.tracks())
        } else {
            items = [TunesVCItem]()
        }
        
        tunesTableView?.reloadData()
        
        let colorTop = UIColor(named: "NavBarBackground")!.cgColor
        let colorBottom = UIColor.black.cgColor
                        
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [colorTop, colorBottom]
            gradientLayer.locations = [0.0, 1.0]
            gradientLayer.frame = self.view.bounds
                    
            self.view.layer.insertSublayer(gradientLayer, at:0)
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    open override var shouldAutorotate: Bool {
        return false
    }
    
    func change(_ currentSong: Song?) {
        playerControlsView?.loopButton?.isSelected = false
        playerControlsView?.playButton?.isSelected = false
        tuneTracks = nil
        recordingTracks = nil
                
        if playerController?.song != currentSong {
            playerController?.stopPlaying()

            playerController = nil

            if let currentSong = currentSong {
                playerController = PlayerController(withSong: currentSong, delegate: self)
            }
        }
        
        tunesTableView?.reloadData()
    }
    
    class func calculateItems(forPlayerTracks playerTracks: [PlayerTrack]) -> [TunesVCItem] {
        let tunes = playerTracks.filter { $0.trackType == .tune }
        
        var newTunes: [PlayerTrack] = []
        
        let titles = ["harmony", "soprano", "tenor", "alto", "bass"]
        
        for title in titles {
            let matches = tunes.filter {
                if let _ = $0.title?.range(of: title, options: .caseInsensitive) {
                    return true
                }
                return false
            }
            
            if let firstObject = matches.first {
                newTunes.append(firstObject)
            }
        }
         
        let tuneTracks = newTunes.count > 0 ? newTunes : tunes
        
        let recordingTracks = playerTracks.filter { $0.trackType == .recording }
        
        let together = tuneTracks + recordingTracks
        
        var items = [TunesVCItem]()
        
        for idx in 0..<together.count {
            let track = together[idx]
            
            let ip = IndexPath(row: idx, section: 0)
            
            let cellID: String? = {
                if track.trackType == .tune {
                    return String(describing: PlayTrackTVCell.self)
                } else if track.trackType == .recording {
                    return String(describing: PlayRecordingTVCell.self)
                }
                return nil
            }()
            
            if let cellID = cellID {
                items.append(TunesVCItem(indexPath: ip, cellID: cellID, track: track))
            }
        }

        /*
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
 */
        
        let mediaLibraryItem = TunesVCItem(
            indexPath: IndexPath(row: items.count, section: 0),
            cellID: String(describing: EnableMusicLibraryTVCell.self),
            track: nil
        )
        
        items.append(mediaLibraryItem)

        let appleMusicItem = TunesVCItem(
            indexPath: IndexPath(row: items.count, section: 0),
            cellID: String(describing: EnableAppleMusicTVCell.self),
            track: nil
        )
        
        items.append(appleMusicItem)
        
        return items
    }
    
    func tunesDidLoad(_ aNotification: Notification?) {
        tunesTableView?.reloadData()
    }
    
    func timePosition() -> TimeInterval {
        return playerController?.timePosition ?? 0.0
    }
    
    // MARK: - NSObject
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - IBActions
    @IBAction func loopButtonPressed() {
        if
            let playerControlsView = playerControlsView,
            let loopButton = playerControlsView.loopButton,
            let playerController = playerController,
            let currentSong = songsManager?.currentSong
        {
            loopButton.isSelected = !loopButton.isSelected
            
            if loopButton.isSelected {
                playerController.loopCounter = UInt8(currentSong.stanzas.count)
                playerControlsView.configureLoopButton(withNumber: playerController.loopCounter)
            } else {
                playerController.loopCounter = 0
            }
        }
    }
    
    @IBAction func playButtonPressed() {
        if tuneTracks?.count == 0 {
            return
        }
        
        if let playerController = playerController {
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
        
        configurePlayerControlsView()
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
            if
                let playerController = playerController,
                let playerControlsView = playerControlsView
            {
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
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return shouldShowAdditionalTunes ? 1 : 0
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        
        let cell  = tableView.dequeueReusableCell(withIdentifier: item.cellID)
        
        if let cell = cell as? PlayTrackTVCell {
            cell.trackTitleLabel?.text = item.track?.title
        } else if
            let cell = cell as? PlayRecordingTVCell
        {
            cell.configureWithAlbumTitle(item.track?.albumTitle, albumArtwork: item.track?.albumArtwork, trackTitle: item.track?.title, artist: item.track?.artist)
        } else if
            let cell = cell as? EnableMusicLibraryTVCell
        
        {
            let authStatus = MPMediaLibrary.authorizationStatus()
            
            switch authStatus {
            case .denied, .restricted, .notDetermined:
                cell.enableMusicLibrarySwitch?.isOn = false
                let action = UIAction { action in
                    MPMediaLibrary.requestAuthorization({ authorizationStatus in
                        OperationQueue.main.addOperation({
                            if authorizationStatus == .authorized {

                            } else {

                            }
                        })
                    })
                }
                cell.enableMusicLibrarySwitch?.addAction(action, for: .valueChanged)
            case .authorized:
                cell.enableMusicLibrarySwitch?.isOn = true
            default:
                cell.enableMusicLibrarySwitch?.isOn = false
            }
        } else if
            let cell = cell as? EnableAppleMusicTVCell
        {
            let authStatus = MPMediaLibrary.authorizationStatus()
            
            switch authStatus {
            case .denied, .restricted, .notDetermined:
                cell.enableAppleMusicSwitch?.isOn = false
                let action = UIAction { action in
                    MPMediaLibrary.requestAuthorization({ authorizationStatus in
                        OperationQueue.main.addOperation({
                            if authorizationStatus == .authorized {

                            } else {

                            }
                        })
                    })
                }
                cell.enableAppleMusicSwitch?.addAction(action, for: .valueChanged)
            case .authorized:
                cell.enableAppleMusicSwitch?.isOn = true
            default:
                cell.enableAppleMusicSwitch?.isOn = false
            }
        }
        
        return cell!
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        
        if let playerControlsView = playerControlsView {
            if
                let track = item.track,
                track.trackType == .tune
            {
                playerController?.playTrack(track, atTime: 0.0, withDelay: 0.0, rate: playerControlsView.currentPlaybackRate())
            } else if
                let track = item.track,
                track.trackType == .recording
            {
                playerController?.playTrack(track, atTime: 0.0, withDelay: 0.0, rate: playerControlsView.currentPlaybackRate())
            }
        }
 
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Helper methods
    
    func hasTableViewHeaders(tableView: UITableView) -> Bool {
        return tableView.numberOfSections > 1
    }
    
    func configurePlayerControlsView() {
        updateProgressView()
        
        if let playerController = playerController {
            if playerController.isPlaying() {
                playerControlsView?.playButton?.setImage(UIImage(systemName: ImageNames.pause.rawValue), for: .normal)
                
                if progressUpdateTimer == nil {
                    initiateProgressUpdateTimer()
                }
            } else {
                invalidateProgressUpdateTimer()
                
                if playerController.isPaused == false {
                    playerControlsView?.timeElapsedLabel?.text = "0:00"
                    playerControlsView?.timeRemainingLabel?.text = "-0:00"
                }
                
                playerControlsView?.playButton?.setImage(UIImage(systemName: ImageNames.play.rawValue), for: .normal)
            }
            
            playerControlsView?.configureLoopButton(withNumber: playerController.loopCounter)
            
            configureSelectedTrackTitleLabel()
        }
    }
    
    func configureSelectedTrackTitleLabel() {
        playerControlsView?.trackTitleLabel?.text = {
            if let currentTrack = self.playerController?.currentTrack {
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
    
    open func headerCell(for tableView: UITableView?) -> UITableViewCell {        
        let cell = tableView?.dequeueReusableCell(withIdentifier: TunesVC.headerCellCellIdentifier) ?? UITableViewCell(style: .default, reuseIdentifier: TunesVC.headerCellCellIdentifier)
        
        if let playerController = playerController {
            if playerController.loadTunesDidFail {
                cell.textLabel?.text = "No Tunes Found"
            } else if songsManager?.currentSong?.isTuneCopyrighted == true {
                cell.textLabel?.text = "No Tunes available for this song."
            } else {
                cell.textLabel?.text = "Loading..."
            }
        }
        
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.font = UIFont(name: "Arial", size: 18.0)
        cell.textLabel?.textColor = UIColor.label
        cell.selectionStyle = .none
        
        return cell
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
    
    // MARK: - MIDI
    func isPlaying() -> Bool {
        return playerController?.isPlaying() ?? false
    }
    
    func pausePlayback() {
        playerController?.pause()
    }
    
    func resumePlayback() {
        playerController?.resume()
    }
    
    func restartTrack() {
        playerController?.restartTrack()
    }
    
    func stopPlaying() {
        playerController?.stopPlaying()
    }
    
    func initiateProgressUpdateTimer() {
        progressUpdateTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(progressTimerUpdate), userInfo: nil, repeats: true)
    }
    
    func invalidateProgressUpdateTimer() {
        progressUpdateTimer?.invalidate()
        progressUpdateTimer = nil
    }
    
    func updateProgressView() {
        if let playerController = playerController {
            if playerController.isPlaying() || playerController.isPaused {
                let duration = playerController.duration()
                let currentPos = playerController.currentPosition()
                
                let progressPercent = Float(currentPos / duration)
                
                tuneProgressBar?.progress = progressPercent
                
                func intervalToString(interval: TimeInterval) -> String {
                    let minutes = Int(interval/60)
                    let seconds = Int(interval - Double(minutes * 60))
                    return "\(minutes):\(seconds < 10 ? "0\(seconds)" : "\(seconds)")"
                }
                
                playerControlsView?.timeElapsedLabel?.text = intervalToString(interval: currentPos)
                playerControlsView?.timeRemainingLabel?.text = "-\(intervalToString(interval: duration - currentPos))"
            } else {
                tuneProgressBar?.progress = 0.0
            }
        }
    }
    
    @objc func progressTimerUpdate() {
        updateProgressView()
    }
    
    // MARK: - PFWPlayerControllerDelegate
    func playerControllerTracksDidChange(_ playerController: PlayerController, tracks: [PlayerTrack]?) {
        if playerController.song == self.songsManager?.currentSong {
            tuneTracks = nil
            recordingTracks = nil
                        
            updateProgressView()
            
            if let tracks = tracks {
                items = TunesVC.calculateItems(forPlayerTracks: tracks)
            } else {
                items = [TunesVCItem]()
            }
            
            tunesTableView?.reloadData()
            configurePlayerControlsView()
        }
    }
    
    func playbackStateDidChangeForPlayerController(_ playerController: PlayerController) {
        if playerController.song == self.songsManager?.currentSong {
            configurePlayerControlsView()
        }
    }
}
