/*
//  TunesViewController.m
//  SongsForWorship
//
//  Created by Phil Loden on 4/28/10. Licensed under the MIT license, as follows:
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

import MediaPlayer

enum PFWTunesVCTableViewSection: Int {
    case tune = 0
    case recording = 1
    case count = 2
}

open class TunesVC: UIViewController, UITableViewDataSource, UITableViewDelegate, AVAudioPlayerDelegate {
    enum ImageNames: String {
        case pause = "pause.fill", play = "play.fill", repeatTrack = "repeat"
    }
    override class var storyboardName: String {
        return "SongDetail"
    }
    private var isObservingcurrentSong = false

    @IBOutlet weak var overlayView: UIView?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var backgroundGradientView: UIView?

    @IBOutlet weak var playerControlsView: PlayerControlsView? {
        didSet {
            if let appConfig = appConfig {
                playerControlsView?.playbackRateSegmentedControl?.isHidden = appConfig.shouldShowPlaybackRateSegmentedControl
            }
        }
    }

    @IBOutlet weak var volumeControl: MPVolumeView? {
        didSet {
            volumeControl?.showsRouteButton = false
        }
    }
    private var progressUpdateTimer: Timer?
    lazy var playerController: PlayerController? = {
        if
            let songsManager = songsManager,
            let currentSong = songsManager.currentSong,
            let currentSongCollection = songsManager.collection(forSong: currentSong)
        {
            return PlayerController(with: currentSong, tuneInfos: currentSongCollection.tuneInfos, delegate: self)
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
    var appConfig: AppConfig!
    var songsManager: SongsManager!
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
        tunesTableView?.register(
            UINib(nibName: noRecordingsFoundClassStr, bundle: Helper.songsForWorshipBundle()),
            forCellReuseIdentifier: noRecordingsFoundClassStr
        )

        let enableRecordingsClassStr = "EnableRecordingsTVCell"
        tunesTableView?.register(
            UINib(nibName: enableRecordingsClassStr, bundle: Helper.songsForWorshipBundle()),
            forCellReuseIdentifier: enableRecordingsClassStr
        )

        let recordingsDisabledClassStr = "RecordingsDisabledTVCell"
        tunesTableView?.register(
            UINib(nibName: recordingsDisabledClassStr, bundle: Helper.songsForWorshipBundle()),
            forCellReuseIdentifier: recordingsDisabledClassStr
        )

        tunesTableView?.register(
            UINib(nibName: "TunesHeaderView", bundle: Helper.songsForWorshipBundle()),
            forHeaderFooterViewReuseIdentifier: "TunesHeaderView"
        )

        tunesTableView?.estimatedRowHeight = 44.0
        tunesTableView?.rowHeight = UITableView.automaticDimension

        if
            let appConfig = appConfig,
            appConfig.shouldShowAdditionalTunes == false
        {
            tableViewHeightConstraint?.constant = 0.0
            tableViewHeightConstraint?.priority = .required
        }

        configurePlayerControlsView()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configurePlayerControlsView()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let backgroundGradientView = backgroundGradientView {
            func gradientLayer() -> CAGradientLayer {
                let colorTop = UIColor(named: "NavBarBackground")!.cgColor
                let colorBottom = UIColor.black.cgColor

                let gradientLayer = CAGradientLayer()
                gradientLayer.colors = [colorTop, colorBottom]
                gradientLayer.locations = [0.0, 1.0]
                gradientLayer.frame.size = backgroundGradientView.bounds.size
                return gradientLayer
            }

            if let bg = backgroundGradientView.layer.sublayers?.first as? CAGradientLayer {
                if bg.frame.size == backgroundGradientView.bounds.size {
                    // do nothing
                } else {
                    backgroundGradientView.layer.replaceSublayer(bg, with: gradientLayer())
                }
            } else {
                backgroundGradientView.layer.insertSublayer(gradientLayer(), at: 0)
            }
        }
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    open override var shouldAutorotate: Bool {
        return false
    }

    func change(_ currentSong: (Song)?) {
        playerControlsView?.loopButton?.isSelected = false
        playerControlsView?.playButton?.isSelected = false
        tuneTracks = nil
        recordingTracks = nil

        if playerController?.song != currentSong {
            playerController?.stopPlaying()

            playerController = nil

            if
                let currentSong = currentSong,
                let currentSongCollection = songsManager?.collection(forSong: currentSong)
            {
                playerController = PlayerController(with: currentSong, tuneInfos: currentSongCollection.tuneInfos, delegate: self)
            }
        }

        tunesTableView?.reloadData()
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
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if hasTableViewHeaders(tableView: tableView) {
            let header = tunesTableView?.dequeueReusableHeaderFooterView(withIdentifier: "TunesHeaderView") as? TunesHeaderView

            header?.headerTitleLabel?.text = {
                if section == 0 {
                    return "Tunes for Sheet Music"
                } else {
                    return "Recordings"
                }
            }()

            return header
        } else {
            return nil
        }
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if hasTableViewHeaders(tableView: tableView) {
            return 54.0
        }
        return 0.0
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        if
            let appConfig = appConfig,
            appConfig.tuneRecordings == false
        {
            return 1
        }
        return PFWTunesVCTableViewSection.count.rawValue
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case PFWTunesVCTableViewSection.tune.rawValue:
            let numRows = tuneTracks?.count ?? 0
            return max(1, numRows)
        case PFWTunesVCTableViewSection.recording.rawValue:
            let numRows = recordingTracks?.count ?? 0
            return max(1, numRows)
        default:
            return 0
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?

        switch indexPath.section {
        case PFWTunesVCTableViewSection.tune.rawValue:
            break
        case PFWTunesVCTableViewSection.recording.rawValue:
            if let recordingTracks = recordingTracks {
                if recordingTracks.count == 0 {
                    cell = recordingHeaderCell(for: tableView)
                } else {
                    let playRecordingTVCell = tableView.dequeueReusableCell(withIdentifier: "PlayRecordingTVCell") as? PlayRecordingTVCell

                    if indexPath.row < recordingTracks.count {
                        let track = recordingTracks[indexPath.row]
                        playRecordingTVCell?.configureWithAlbumTitle(track.albumTitle,
                                                                     albumArtwork: track.albumArtwork,
                                                                     trackTitle: track.title,
                                                                     artist: track.artist)
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

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case PFWTunesVCTableViewSection.tune.rawValue:
            if
                let playerControlsView = playerControlsView,
                let tuneTracks = tuneTracks,
                indexPath.row < tuneTracks.count
            {
                let track = tuneTracks[indexPath.row]
                playerController?.playTrack(track, atTime: 0.0, withDelay: 0.0, rate: playerControlsView.currentPlaybackRate())
            }
        case PFWTunesVCTableViewSection.recording.rawValue:
            if
                let playerControlsView = playerControlsView,
                let recordingTracks = recordingTracks,
                indexPath.row < recordingTracks.count
            {
                let track = recordingTracks[indexPath.row]
                playerController?.playTrack(track, atTime: 0.0, withDelay: 0.0, rate: playerControlsView.currentPlaybackRate())
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
                                // FIXME:
                                //weakSelf?.playerController.song = weakSelf?.songsManager?.currentSong
                                //weakSelf?.playerController.collection = weakSelf?.songsManager?.currentCollection
                            } else {
                                // user did not authorize
                                weakSelf?.tunesTableView?.reloadData()
                            }
                        })
                    })
                case .authorized:
                    break
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
        let cell = tableView?.dequeueReusableCell(
            withIdentifier: TunesVC.headerCellCellIdentifier) ?? UITableViewCell(style: .default, reuseIdentifier: TunesVC.headerCellCellIdentifier
            )

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
        if abbreviation == "a" {
            return "Alto"
        } else if abbreviation == "b" {
            return "Bass"
        } else if abbreviation == "s" {
            return "Soprano"
        } else if abbreviation == "t" {
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
}

extension TunesVC: PlayerControllerDelegate {
    func playerControllerTracksDidChange(_ playerController: PlayerController, tracks: [PlayerTrack]?) {
        if playerController.song == self.songsManager?.currentSong {
            tuneTracks = nil
            recordingTracks = nil

            let tunes = tracks?.filter { $0.trackType == .tune }

            var newTunes: [PlayerTrack] = []

            let titles = ["harmony", "soprano", "tenor", "alto", "bass"]

            for title in titles {
                let matches = tunes?.filter {
                    if $0.title?.range(of: title, options: .caseInsensitive) != nil {
                        return true
                    }
                    return false
                }

                if let firstObject = matches?.first {
                    newTunes.append(firstObject)
                }
            }

            tuneTracks = newTunes.count > 0 ? newTunes : tunes

            recordingTracks = tracks?.filter { $0.trackType == .recording }
            updateProgressView()
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

extension TunesVC: HasSongsManager {}

extension TunesVC: PlayerControlsViewDelegate {
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
}

extension TunesVC: HasAppConfig {}
*/


 //  TunesViewController.m
 //  PsalmsForWorship
 //
 //  Created by PHILIP LODEN on 4/28/10.
 //  Copyright 2010 Deo Volente, LLC. All rights reserved.
 //

 import MediaPlayer

 struct TunesVCItem: Equatable {
     let indexPath: IndexPath
     let cellID: String
     let track: PlayerTrack?
 }

 open class TunesVC: UIViewController, UITableViewDataSource, UITableViewDelegate, AVAudioPlayerDelegate, PlayerControlsViewDelegate, PlayerControllerDelegate {
     enum ImageNames: String {
         case pause = "pause.fill", play = "play.fill", repeatTrack = "repeat"
     }
     override class var storyboardName: String {
         get {
             return "SongDetail"
         }
     }
     private var isObservingcurrentSong = false

     var appConfig: AppConfig!
     var songsManager: SongsManager!

     var queue: OperationQueue = {
         var queue = OperationQueue()
         queue.name = "Tunes loader queue"
         queue.maxConcurrentOperationCount = 1
         return queue
     }()

     @IBOutlet weak var playerControlsView: PlayerControlsView?
     @IBOutlet weak var overlayView: UIView?
     @IBOutlet weak var backgroundGradientView: UIView?
     @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
     @IBOutlet weak var volumeControl: MPVolumeView? {
         didSet {
             volumeControl?.showsRouteButton = false
         }
     }
     private var progressUpdateTimer: Timer?
     lazy var playerController: PlayerController? = {
         if
             let currentSong = songsManager.currentSong,
             let currentSongCollection = songsManager.collection(forSong: currentSong)
         {
             return PlayerController(with: currentSong, tuneInfos: currentSongCollection.tuneInfos, delegate: self, queue: queue)
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
     var loadedPsalmNumber: String?
     @IBOutlet weak var tunesTableView: UITableView?
     @IBOutlet weak var tuneProgressBar: UIProgressView?
     @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint?
     var lastSelectedCell: IndexPath?
     lazy var shouldShowAdditionalTunes: Bool = {
         return appConfig.shouldShowAdditionalTunes ?? false
     }()
     lazy var tuneRecordings: Bool = {
         return appConfig.tuneRecordings ?? false
     }()
     var items: [TunesVCItem] = [TunesVCItem]()

     // MARK: - UIViewController
     open override func viewDidLoad() {
         super.viewDidLoad()

         hideOverlay()

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
             playerController.song == songsManager?.currentSong
         {
             if playerController.state == .loadingTunesDidSucceed {
                 items = TunesVC.calculateItems(forPlayerTracks: playerController.tracks())
             } else if playerController.state == .loadingSelectedTuneForPlayback {
                 showOverlay()
             }
         } else {
             items = [TunesVCItem]()
         }

         tunesTableView?.reloadData()
     }

     open override func viewDidLayoutSubviews() {
         super.viewDidLayoutSubviews()

         if let backgroundGradientView = backgroundGradientView {
             func gradientLayer() -> CAGradientLayer {
                 let colorTop = UIColor(named: "NavBarBackground")!.cgColor
                 let colorBottom = UIColor.black.cgColor

                 let gradientLayer = CAGradientLayer()
                 gradientLayer.colors = [colorTop, colorBottom]
                 gradientLayer.locations = [0.0, 1.0]
                 gradientLayer.frame.size = backgroundGradientView.bounds.size
                 return gradientLayer
             }

             if let bg = backgroundGradientView.layer.sublayers?.first as? CAGradientLayer {
                 if bg.frame.size == backgroundGradientView.bounds.size {
                     // do nothing
                 } else {
                     backgroundGradientView.layer.replaceSublayer(bg, with: gradientLayer())
                 }
             } else {
                 backgroundGradientView.layer.insertSublayer(gradientLayer(), at: 0)
             }
         }
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

         if playerController?.song != currentSong {
             playerController?.stopPlaying()

             playerController = nil

             if
                let currentSong = currentSong,
                let currentSongCollection = songsManager.collection(forSong: currentSong)
             {
                 playerController = PlayerController(with: currentSong, tuneInfos: currentSongCollection.tuneInfos, delegate: self, queue: queue)
             }
         }

         tunesTableView?.reloadData()
         tunesTableView?.contentOffset = .zero
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

         let notTuneTracks = playerTracks.filter { $0.trackType != .tune }

         let together = tuneTracks + notTuneTracks

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

     func musicLibrarySwitchAction(isEnabled: Bool) -> UIAction {
         if isEnabled {
             let action = UIAction { action in
                 if let settings = Settings(fromUserDefaults: .standard) {
                     _ = settings.new(withShouldShowMusicLibrary: false).save(toUserDefaults: .standard)
                 }
             }
             return action
         } else {
             let action = UIAction { action in
                 if let settings = Settings(fromUserDefaults: .standard) {
                     _ = settings.new(withShouldShowMusicLibrary: true).save(toUserDefaults: .standard)
                 }
                 MPMediaLibrary.requestAuthorization({ authorizationStatus in
                     OperationQueue.main.addOperation({ [weak self] in
                         if authorizationStatus == .authorized {
                             self?.playerController?.loadTunes()
                         } else if let cell = self?.tunesTableView?.visibleCells.first(where: { $0 is EnableMusicLibraryTVCell} ) as? EnableMusicLibraryTVCell {
                             let alertController = UIAlertController(title: "Cannot Access Apple Music", message: "There was an error accessing Apple Music.", preferredStyle: .alert)
                             alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                                 cell.enableMusicLibrarySwitch?.setOn(false, animated: true)
                             }))
                             self?.present(alertController, animated: true)
                         }
                     })
                 })
             }
             return action
         }
     }

     func appleMusicSwitchAction(isEnabled: Bool) -> UIAction {
         if isEnabled {
             let action = UIAction { action in
                 if let settings = Settings(fromUserDefaults: .standard) {
                     _ = settings.new(withShouldShowAppleMusic: false).save(toUserDefaults: .standard)
                 }
             }
             return action
         } else {
             let action = UIAction { action in
                 if let settings = Settings(fromUserDefaults: .standard) {
                     _ = settings.new(withShouldShowAppleMusic: true).save(toUserDefaults: .standard)
                 }
                 MPMediaLibrary.requestAuthorization({ authorizationStatus in
                     OperationQueue.main.addOperation({ [weak self] in
                         if authorizationStatus == .authorized {
                             self?.playerController?.loadTunes()
                         } else if let cell = self?.tunesTableView?.visibleCells.first(where: { $0 is EnableAppleMusicTVCell} ) as? EnableAppleMusicTVCell {
                             cell.enableAppleMusicSwitch?.setOn(false, animated: true)
                         }
                     })
                 })
             }
             return action
         }
     }

     static func musicLibraryIsEnabled(settings: Settings?) -> Bool {
         var isEnabled: Bool

         let authStatus = MPMediaLibrary.authorizationStatus()

         switch authStatus {
         case .denied, .restricted, .notDetermined:
             isEnabled = false
         case .authorized:
             isEnabled = true
         default:
             isEnabled = false
         }

         if let settings = settings {
             isEnabled = isEnabled && settings.shouldShowMusicLibrary
         }

         return isEnabled
     }

     static func appleMusicIsEnabled(settings: Settings?) -> Bool {
         var isEnabled: Bool

         let authStatus = MPMediaLibrary.authorizationStatus()

         switch authStatus {
         case .denied, .restricted, .notDetermined:
             isEnabled = false
         case .authorized:
             isEnabled = true
         default:
             isEnabled = false
         }

         if let settings = settings {
             isEnabled = isEnabled && settings.shouldShowAppleMusic
         }

         return isEnabled
     }

     public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let item = items[indexPath.row]

         let cell  = tableView.dequeueReusableCell(withIdentifier: item.cellID)

         if let cell = cell as? PlayTrackTVCell {
             cell.trackTitleLabel?.text = item.track?.title
         } else if
             let cell = cell as? PlayRecordingTVCell
         {
             if let albumArtworkImage = item.track?.albumArtworkImage {
                 cell.configureWithAlbumTitle(item.track?.albumTitle, albumArtwork: albumArtworkImage, trackTitle: item.track?.title, artist: item.track?.artist)
             } else {
                 cell.configureWithAlbumTitle(item.track?.albumTitle, albumArtwork: nil, trackTitle: item.track?.title, artist: item.track?.artist)

                 if let imageURL = item.track?.albumArtwork?.imageURL(size: CGSize(width: 120, height: 120)) {
                     (UIApplication.shared.delegate as? SFWAppDelegate)?.imageCacheManager.fetchImage(url: imageURL, completion: { (image) in
                         cell.configureWithAlbumTitle(item.track?.albumTitle, albumArtwork: image, trackTitle: item.track?.title, artist: item.track?.artist)
                     })
                 }
             }
         } else if
             let cell = cell as? EnableMusicLibraryTVCell
         {
             let isEnabled = Self.musicLibraryIsEnabled(settings: Settings.init(fromUserDefaults: .standard))
             cell.enableMusicLibrarySwitch?.isOn = isEnabled
             cell.enableMusicLibrarySwitch?.addAction(self.musicLibrarySwitchAction(isEnabled: isEnabled), for: .valueChanged)
         } else if
             let cell = cell as? EnableAppleMusicTVCell
         {
             let isEnabled = Self.appleMusicIsEnabled(settings: Settings.init(fromUserDefaults: .standard))
             cell.enableAppleMusicSwitch?.isOn = isEnabled
             cell.enableAppleMusicSwitch?.addAction(self.appleMusicSwitchAction(isEnabled: isEnabled), for: .valueChanged)
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

     func showOverlay() {
         if let overlayView = overlayView {
             overlayView.isHidden = false
             overlayView.superview?.bringSubviewToFront(overlayView)
             activityIndicator?.startAnimating()
         }
     }

     func hideOverlay() {
         if let overlayView = overlayView {
             overlayView.isHidden = true
             overlayView.superview?.sendSubviewToBack(overlayView)
             activityIndicator?.stopAnimating()
         }
     }

     // MARK: - PFWPlayerControllerDelegate
     func playerControllerTracksDidChange(_ playerController: PlayerController, tracks: [PlayerTrack]?) {
         if playerController.song == self.songsManager?.currentSong {
             if let tracks = tracks {
                 let newItems = Self.calculateItems(forPlayerTracks: tracks)

                 if items != newItems {
                     updateProgressView()
                     items = newItems
                     tunesTableView?.reloadData()
                     configurePlayerControlsView()
                 }
             } else {
                 updateProgressView()
                 items = Self.calculateItems(forPlayerTracks: [PlayerTrack]())
                 tunesTableView?.reloadData()
                 configurePlayerControlsView()
             }
         }
     }

     func playbackStateDidChangeForPlayerController(_ playerController: PlayerController) {
         if playerController.song == self.songsManager?.currentSong {
             configurePlayerControlsView()

             if playerController.state == .loadingSelectedTuneForPlayback {
                 showOverlay()
             } else {
                 hideOverlay()
             }
         }
     }
 }

extension TunesVC: HasAppConfig {}
extension TunesVC: HasSongsManager {}
