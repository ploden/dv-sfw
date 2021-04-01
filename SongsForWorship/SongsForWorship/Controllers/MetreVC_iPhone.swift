//  Converted to Swift 5.1 by Swiftify v5.1.17924 - https://objectivec2swift.com/
//
//  MetreViewController.m
//  PsalmsForWorship
//
//  Created by PHILIP LODEN on 4/28/10.
//  Copyright 2010 Deo Volente, LLC. All rights reserved.
//

import UIKit

class MetreVC_iPhone: UIViewController, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, HasSongsToDisplay, HasSongsManager {
    enum imageNames: String {
        case play = "play.fill", pause = "pause.fill", isFavorite = "bookmark.fill", isNotFavorite = "bookmark"
    }
    override class var storyboardName: String {
        get {
            return "SongDetail"
        }
    }
    var songsToDisplay: [Song]?
    var songsManager: SongsManager?
    var newWindow: UIWindow?
    lazy var tunesVC: TunesVC = {
        return TunesVC.pfw_instantiateFromStoryboard() as! TunesVC
    }()
    private var hasScrolled = false
    private var shouldScrollToStartingIndex = false
    lazy private var playerController: PlayerController? = {
        if
            let songsManager = songsManager,
            let currentSong = songsManager.currentSong
        {
            return PlayerController(withSong: currentSong, delegate: self)            
        }
        return nil
    }()
    
    @IBOutlet private var favoriteBarButtonItem: UIBarButtonItem?
    @IBOutlet private var playBarButtonItem: UIBarButtonItem?
    @IBOutlet private var showPlayerBarButtonItem: UIBarButtonItem?
    @IBOutlet weak var collectionView: UICollectionView?
    @IBOutlet weak var toolbar: UIToolbar?
    
    private var indexPathOfLastDisplayedCell: IndexPath?
    lazy private var activityIndicatorBarButtonItem: UIBarButtonItem = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.startAnimating()
        return UIBarButtonItem(customView: activityIndicator)
    }()
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = songsManager?.currentSong?.number
        
        shouldScrollToStartingIndex = true
        
        configureFavoriteBarButtonItem()
        configurePlayerBarButtonItems()
        
        collectionView?.register(UINib(nibName: "MetreCVCell", bundle: Helper.songsForWorshipBundle()), forCellWithReuseIdentifier: "MetreCVCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if
            let isHidden = navigationController?.isNavigationBarHidden,
            isHidden == true
        {
            navigationController?.setNavigationBarHidden(false, animated: false)
            collectionView?.collectionViewLayout.invalidateLayout()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged(_:)), name: UIDevice.orientationDidChangeNotification, object: UIDevice.current)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !(presentedViewController != nil) {
            NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: UIDevice.current)
        }
    }
    
    @objc func orientationChanged(_ notification: Notification?) {
        if let device = notification?.object as? UIDevice {
            switch device.orientation {
            case .portraitUpsideDown:
                // start special animation
                break
            case .portrait:
                newWindow?.rootViewController?.dismiss(animated: true) {
                    OperationQueue.main.addOperation { [weak self] in
                        if let rootVC = self?.newWindow?.rootViewController as? RootVC {
                            /*
                             There's a memory leak related to the sheet music window.
                             I can't release the root VC, but we can minimize the damage
                             by releasing everything inside it. -PCL 2-15-2020 
                             */
                            rootVC.sheetMusicVC = nil
                        }
                        self?.newWindow?.isHidden = true
                        
                        if let app = UIApplication.shared.delegate as? PsalterAppDelegate {
                            app.window?.makeKeyAndVisible()
                        }
                        
                        self?.newWindow?.windowScene = nil                               
                        self?.newWindow?.subviews.forEach { $0.removeFromSuperview() }
                        self?.newWindow?.rootViewController?.dismiss(animated: false, completion: nil)
                        self?.newWindow?.rootViewController = nil
                        self?.newWindow?.rootViewController?.view.removeFromSuperview()
                        self?.newWindow?.windowLevel = .normal - 1
                        
                        self?.newWindow = nil
                    }
                }
                break
            case .landscapeLeft, .landscapeRight:
                if
                    let song = songsManager?.currentSong,
                    song.isTuneCopyrighted == false
                {
                    showSheetMusic(for: device.orientation)
                }
            default:
                break
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if
            let collectionView = collectionView,
            let current = songsManager?.currentSong,
            let idx = songsManager?.songsToDisplay?.firstIndex(of: current)
        {
            if shouldScrollToStartingIndex && idx < collectionView.numberOfItems(inSection: 0) {
                collectionView.scrollToItem(at: IndexPath(item: idx, section: 0), at: [], animated: false)
                shouldScrollToStartingIndex = false
            }
        }
    }
    
    // MARK: - rotation
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    // MARK: - collection view flow layout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.collectionView?.bounds.size ?? .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return songsManager?.songsToDisplay?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cvc = collectionView.dequeueReusableCell(withReuseIdentifier: "MetreCVCell", for: indexPath) as? MetreCVCell
        let song = SongsManager.songAtIndex(indexPath.row, allSongs: songsManager?.songsToDisplay)
        cvc?.song = song
        
        return cvc!
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if hasScrolled {
            navigationItem.title = nil
        } else {
            hasScrolled = true
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let collectionView = collectionView {
            let center = collectionView.convert(collectionView.center, from: collectionView.superview)
            let ip = collectionView.indexPathForItem(at: center)
            
            if let ip = ip {
                if !(navigationItem.title != nil) || indexPathOfLastDisplayedCell?.compare(ip) != .orderedSame {
                    let song = SongsManager.songAtIndex(ip.row, allSongs: songsManager?.songsToDisplay)
                    songsManager?.setcurrentSong(song, songsToDisplay: songsManager?.songsToDisplay)
                }
            }
            self.indexPathOfLastDisplayedCell = ip
        }
        if playerController?.song != songsManager?.currentSong {
            playerController?.stopPlaying()
            playerController = nil
            if
                let songsManager = songsManager,
                let currentSong = songsManager.currentSong
            {
                self.playerController = PlayerController(withSong: currentSong, delegate: self)
            }
        }
        navigationItem.title = songsManager?.currentSong?.number
        configurePlayerBarButtonItems()
        configureFavoriteBarButtonItem()
    }
    
    func showSheetMusic(for toInterfaceOrientation: UIDeviceOrientation) {
        if newWindow == nil {
            let defaults = UserDefaults.standard
            defaults.set(Date(), forKey: "firstTime")
            NSUbiquitousKeyValueStore.default.set(Date(), forKey: "firstTime")
            
            let currentSong = songsManager?.currentSong
            
            if let currentSong = currentSong {
                newWindow = UIWindow(frame: UIScreen.main.bounds)
                let newVC = RootVC(nibName: nil, bundle: Helper.songsForWorshipBundle())
                let sheetMusicVC = SheetMusicVC_iPhone.pfw_instantiateFromStoryboard() as? SheetMusicVC_iPhone
                sheetMusicVC?.songsManager = songsManager
                sheetMusicVC?.song = currentSong
                sheetMusicVC?.orientation = toInterfaceOrientation
                newVC.sheetMusicVC = sheetMusicVC
                newVC.view.backgroundColor = .clear
                newWindow?.rootViewController = newVC
                newWindow?.windowLevel = UIWindow.Level.alert + 1
                newWindow?.makeKeyAndVisible()
                newWindow?.isHidden = false
                sheetMusicVC?.modalPresentationStyle = .fullScreen
            }
        }
    }
    
    // MARK: - Helpers
    func configureFavoriteBarButtonItem() {
        let img: UIImage? = {
            if
                let songsManager = songsManager,
                let currentSong = songsManager.currentSong,
                FavoritesSyncronizer.isFavorite(currentSong, songsManager: songsManager)
            {
                return UIImage(systemName: imageNames.isFavorite.rawValue)
            } else {
                return UIImage(systemName: imageNames.isNotFavorite.rawValue)
            }
        }()
        
        favoriteBarButtonItem?.image = img        
    }
    
    func showActivityIndicatorBarButtonItem(replacing item: UIBarButtonItem?) {
        if
            let item = item,
            let idx = toolbar?.items?.firstIndex(of: item)
        {
            toolbar?.items?.insert(activityIndicatorBarButtonItem, at: idx)
            toolbar?.items?.remove(at: idx+1)
        }
    }

    func showPlayBarButtonItem() {
        if
            let playBarButtonItem = playBarButtonItem,
            let idx = toolbar?.items?.firstIndex(of: activityIndicatorBarButtonItem),
            toolbar?.items?.contains(playBarButtonItem) == false
        {
            toolbar?.items?.insert(playBarButtonItem, at: idx)
            toolbar?.items?.remove(at: idx+1)
        }
    }
    
    func showShowPlayerBarButtonItem() {
        if
            let showPlayerBarButtonItem = showPlayerBarButtonItem,
            let idx = toolbar?.items?.firstIndex(of: activityIndicatorBarButtonItem),
            toolbar?.items?.contains(showPlayerBarButtonItem) == false
        {
            toolbar?.items?.insert(showPlayerBarButtonItem, at: idx)
            toolbar?.items?.remove(at: idx+1)
        }
    }
    
    func configurePlayerBarButtonItems() {
        func defaulConfig() {
            showPlayBarButtonItem()
            playBarButtonItem?.isEnabled = true
            playBarButtonItem?.image = UIImage(systemName: imageNames.play.rawValue)
            showPlayerBarButtonItem?.isEnabled = true
        }
        
        if
            let playerController = playerController,
            let currentSong = songsManager?.currentSong
        {
            if playerController.song == currentSong {
                if playerController.isPlaying() {
                    showPlayBarButtonItem()
                    showShowPlayerBarButtonItem()
                    playBarButtonItem?.image = UIImage(systemName: imageNames.pause.rawValue)
                    playBarButtonItem?.isEnabled = true
                    showPlayerBarButtonItem?.isEnabled = true
                } else if playerController.state == .loadingTunes {
                    if toolbar?.items?.contains(activityIndicatorBarButtonItem) == false {
                        showActivityIndicatorBarButtonItem(replacing: showPlayerBarButtonItem)
                    }
                } else if playerController.state == .loadingTunesDidFail {
                    showPlayBarButtonItem()
                    showShowPlayerBarButtonItem()
                    playBarButtonItem?.image = UIImage(systemName: imageNames.play.rawValue)
                    playBarButtonItem?.isEnabled = false
                    showPlayerBarButtonItem?.isEnabled = false
                } else if playerController.state == .loadingTunesDidSucceed || playerController.state == .tunesNotLoaded {
                    showPlayBarButtonItem()
                    showShowPlayerBarButtonItem()
                    playBarButtonItem?.image = UIImage(systemName: imageNames.play.rawValue)
                    playBarButtonItem?.isEnabled = true
                    showPlayerBarButtonItem?.isEnabled = true
                }
            } else {
                defaulConfig()
            }
        } else {
            playBarButtonItem?.isEnabled = false
            showPlayerBarButtonItem?.isEnabled = false
        }
    }
    
    // MARK: - IBActions
    @IBAction func favoriteBarButtonItemTapped(_ sender: Any) {
        if
            let songsManager = songsManager,
            let currentSong = songsManager.currentSong
        {
            
            if FavoritesSyncronizer.isFavorite(currentSong, songsManager: songsManager) {
                FavoritesSyncronizer.removeFromFavorites(currentSong, songsManager: songsManager)
            } else {
                FavoritesSyncronizer.addToFavorites(currentSong, songsManager: songsManager)
            }
            
            configureFavoriteBarButtonItem()
        }
    }
    
    @IBAction func playTapped(_ sender: Any) {
        if playerController == nil || playerController?.song != songsManager?.currentSong {
            if
                let songsManager = songsManager,
                let currentSong = songsManager.currentSong                
            {
                self.playerController = PlayerController(withSong: currentSong, delegate: self)
            }
        }
        
        if let playerController = playerController {
            if playerController.isPlaying() {
                playerController.pause()
            } else if playerController.isPaused {
                playerController.resume()
            } else if playerController.state == .tunesNotLoaded {
                showActivityIndicatorBarButtonItem(replacing: playBarButtonItem)
                showPlayerBarButtonItem?.isEnabled = false
                playerController.loadTunes()
            } else if playerController.state == .loadingTunesDidSucceed {
                if let currentTrack = playerController.currentTrack {
                    playerController.playTrack(currentTrack, atTime: 0.0, withDelay: 0.0, rate: 1.0)
                }
            }
        }
        
        configurePlayerBarButtonItems()
    }
    
    @IBAction func showPlayerTapped(_ sender: Any) {
        if playerController == nil || playerController?.song != songsManager?.currentSong {
            if let currentSong = songsManager?.currentSong {
                self.playerController = PlayerController(withSong: currentSong, delegate: self)
            }
        }
        
        if let playerController = playerController {
            if playerController.state == .loadingTunesDidSucceed {
                showTunesVC()
            } else {
                showActivityIndicatorBarButtonItem(replacing: showPlayerBarButtonItem)
                playBarButtonItem?.isEnabled = false
                playerController.loadTunes()
            }
        }
    }
    
    func showTunesVC() {
        tunesVC.songsManager = songsManager
        tunesVC.playerController = playerController
        tunesVC.modalPresentationStyle = .popover
        
        tunesVC.popoverPresentationController?.barButtonItem = showPlayerBarButtonItem
        
        if let pres = tunesVC.presentationController {
            pres.delegate = self
        }
        
        tunesVC.popoverPresentationController?.backgroundColor = tunesVC.view.backgroundColor
        
        tunesVC.preferredContentSize = CGSize(width: 375, height: 155)
        
        present(tunesVC, animated: true, completion: nil)
    }
    
    // MARK: - Custom getters
}

extension MetreVC_iPhone: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if let presentedVC = presentationController.presentedViewController as? TunesVC {
            presentedVC.playerController?.delegate = self
            configurePlayerBarButtonItems()
        }
    }
}

extension MetreVC_iPhone: PlayerControllerDelegate {
    func playerControllerTracksDidChange(_ playerController: PlayerController, tracks: [PlayerTrack]?) {
        
        if playerController.song == songsManager?.currentSong {
            if playerController.state == .loadingTunesDidSucceed {
                if
                    let playBarButtonItem = playBarButtonItem,
                    toolbar?.items?.contains(activityIndicatorBarButtonItem) == true && toolbar?.items?.contains(playBarButtonItem) == false
                {
                    if let currentTrack = playerController.currentTrack {
                        playerController.playTrack(currentTrack, atTime: 0.0, withDelay: 0.0, rate: 1.0)
                    }
                } else if
                    let showPlayerBarButtonItem = showPlayerBarButtonItem,
                    toolbar?.items?.contains(activityIndicatorBarButtonItem) == true && toolbar?.items?.contains(showPlayerBarButtonItem) == false
                {
                    showTunesVC()
                }
            }
        }
        
        configurePlayerBarButtonItems()
    }
    
    func playbackStateDidChangeForPlayerController(_ playerController: PlayerController) {
        configurePlayerBarButtonItems()
    }
    
}
