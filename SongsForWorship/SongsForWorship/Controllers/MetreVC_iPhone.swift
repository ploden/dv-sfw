//  Converted to Swift 5.1 by Swiftify v5.1.17924 - https://objectivec2swift.com/
//
//  MetreViewController.m
//  PsalmsForWorship
//
//  Created by PHILIP LODEN on 4/28/10.
//  Copyright 2010 Deo Volente, LLC. All rights reserved.
//

import UIKit

class MetreVC_iPhone: UIViewController, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, HasSongsToDisplay, HasSongsManager, HasSettings, PsalmObserver {
    @objc func songDidChange(_ notification: Notification) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            scrollToCurrentSong()
        }
    }
    
    var settings: Settings? {
        didSet {
            oldValue?.removeObserver(forSettings: self)
            settings?.addObserver(forSettings: self)
        }
    }
    
    enum imageNames: String {
        case play = "play.fill", pause = "pause.fill", isFavorite = "bookmark.fill", isNotFavorite = "bookmark"
    }
    override class var storyboardName: String {
        get {
            return "SongDetail"
        }
    }
    var songsToDisplay: [Song]?
    var songsManager: SongsManager? {
        didSet {
            oldValue?.removeObserver(forcurrentSong: self)
            songsManager?.addObserver(forcurrentSong: self)
        }
    }
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
    var queue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Render pdf queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    @IBOutlet private var favoriteBarButtonItem: UIBarButtonItem?
    @IBOutlet private var playBarButtonItem: UIBarButtonItem?
    @IBOutlet private var showPlayerBarButtonItem: UIBarButtonItem?
    @IBOutlet weak var collectionView: UICollectionView?
    
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
        
        collectionView?.register(UINib(nibName: String(describing: MetreCVCell.self), bundle: Helper.songsForWorshipBundle()), forCellWithReuseIdentifier: String(describing: MetreCVCell.self))
        collectionView?.register(UINib(nibName: String(describing: SheetMusicCVCell.self), bundle: Helper.songsForWorshipBundle()), forCellWithReuseIdentifier: String(describing: SheetMusicCVCell.self))
        collectionView?.register(UINib(nibName: String(describing: ScrollingSheetMusicCVCell.self), bundle: Helper.songsForWorshipBundle()), forCellWithReuseIdentifier: String(describing: ScrollingSheetMusicCVCell.self))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setToolbarHidden(false, animated: true)
        navigationController?.toolbar.isTranslucent = false
        
        if
            let isHidden = navigationController?.isNavigationBarHidden,
            isHidden == true
        {
            navigationController?.setNavigationBarHidden(false, animated: false)
            collectionView?.collectionViewLayout.invalidateLayout()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        shouldScrollToStartingIndex = true
        
        let animated = true
        
        if size.width > size.height {
            navigationController?.hidesBarsOnTap = true
            navigationItem.setHidesBackButton(true, animated: animated)
        } else {
            navigationController?.hidesBarsOnTap = false
            navigationController?.setNavigationBarHidden(false, animated: animated)
            navigationController?.setToolbarHidden(false, animated: animated)
            navigationItem.setHidesBackButton(false, animated: animated)
        }
        
        if let collectionView = collectionView {
            let i = Int(collectionView.contentOffset.x / collectionView.frame.size.width)
            let numItems = collectionView.numberOfItems(inSection: 0)
            
            if numItems > 0 {
                let indexPathBeforeTransitionToSize = IndexPath(item: min(i, numItems - 1), section: 0)
                
                coordinator.animate(alongsideTransition: { context in
                    collectionView.alpha = 0.0
                }) { context in
                    UIView.animate(withDuration: 0.15, animations: {
                        collectionView.alpha = 1.0
                    })
                    
                    collectionView.collectionViewLayout.invalidateLayout()
                    collectionView.reloadData()
                    
                    if indexPathBeforeTransitionToSize.row < collectionView.numberOfItems(inSection: indexPathBeforeTransitionToSize.section) {
                        collectionView.scrollToItem(at: indexPathBeforeTransitionToSize, at: .left, animated: false)
                    }
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //if shouldScrollToStartingIndex {
            //scrollToCurrentSong()
            //shouldScrollToStartingIndex = false
        //}
    }
    
    func scrollToCurrentSong() {
        if
            let collectionView = collectionView,
            let current = songsManager?.currentSong,
            let songsToDisplay = songsManager?.songsToDisplay,
            let idx = songsToDisplay.firstIndex(of: current)
        {
            if shouldShowPDF() {
                let pageNum = PDFPageView.pageNumberForPsalm(current, allSongs: songsToDisplay, idx: nil)
                
                if
                    pageNum < collectionView.numberOfItems(inSection: 0)
                {
                    print("pageNum: \(pageNum)")
                    let item = IndexPath(item: pageNum, section: 0)
                    collectionView.layoutIfNeeded()
                    collectionView.scrollToItem(at: item, at: .centeredHorizontally, animated: false)
                }
            } else {
                if idx < collectionView.numberOfItems(inSection: 0) {
                    collectionView.scrollToItem(at: IndexPath(item: idx, section: 0), at: [], animated: false)
                }
            }
        }
    }
    
    // MARK: - rotation
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    override var shouldAutorotate: Bool {
        return true
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
        if shouldShowPDF() {
            if let songsToDisplay = songsManager?.songsToDisplay {
                let numberOfPages = PDFPageView.numberOfPages(songsToDisplay)
                return numberOfPages
            }
        }
        return songsManager?.songsToDisplay?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellID: String = {
            if let settings = settings {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    // iPad
                    return String(describing: settings.shouldShowSheetMusic_iPad ? SheetMusicCVCell.self : MetreCVCell.self)
                } else {
                    // iPhone
                    if collectionView.frame.size.width > collectionView.frame.size.height {
                        // landscape
                        return String(describing: settings.shouldShowSheetMusicInLandscape_iPhone ? ScrollingSheetMusicCVCell.self : MetreCVCell.self)
                    } else {
                        // portrait
                        return String(describing: settings.shouldShowSheetMusicInPortrait_iPhone ? SheetMusicCVCell.self : MetreCVCell.self)
                    }
                }
            }
            return String(describing: MetreCVCell.self)
        }()
        
        let cvc = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath)
            
        if
            let songsManager = songsManager,
            let songsToDisplay = songsManager.songsToDisplay,
            let song = self.song(forIndexPath: indexPath, songsToDisplay: songsToDisplay)
        {
            if let cvc = cvc as? MetreCVCell {
                cvc.song = song
            } else if let cvc = cvc as? SheetMusicCVCell {
                cvc.configure(withPageNumber: indexPath.item, pdf: song.collection.pdf, allSongs: songsToDisplay, pdfRenderingConfigs: song.collection.pdfRenderingConfigs_iPhone, queue: queue)
            } else if let cvc = cvc as? ScrollingSheetMusicCVCell {
                var containerViewHeight: CGFloat
                
                if collectionView.frame.size.width == 568.0 {
                    // iPhone 5
                    containerViewHeight = 938.0
                } else if collectionView.frame.size.width == 480.0 {
                    // iPhone < 5
                    containerViewHeight = 788.0
                } else if collectionView.frame.size.width == 667 {
                    // iPhone 6
                    containerViewHeight = 1070.0
                } else if collectionView.frame.size.width == 736 {
                    // iPhone 6 Plus
                    containerViewHeight = 1176.0
                } else if collectionView.frame.size.width == 926 {
                    // iPhone 12 Pro Max
                    containerViewHeight = 1246.0
                } else if collectionView.frame.size.width == 808 {
                    // iPhone 11 Pro Max
                    containerViewHeight = 1296.0
                } else if collectionView.frame.size.width == 724 {
                  // iPhone 11 Pro
                    containerViewHeight = 1246.0
                } else if collectionView.frame.size.width == 800 {
                    // iPhone 11
                    containerViewHeight = 1246.0
                } else {
                    // iPhone X
                    containerViewHeight = 1246.0
                }

                cvc.configure(withPageNumber: indexPath.item, pdf: song.collection.pdf, allSongs: songsToDisplay, pdfRenderingConfigs: song.collection.pdfRenderingConfigs_iPhone, queue: queue, height: containerViewHeight)
            }
        }
        
        return cvc
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
            
            if
                let ip = ip,
                let songsToDisplay = songsManager?.songsToDisplay
            {
                if !(navigationItem.title != nil) || indexPathOfLastDisplayedCell?.compare(ip) != .orderedSame {
                    let song = self.song(forIndexPath: ip, songsToDisplay: songsToDisplay)
                    songsManager?.setcurrentSong(song, songsToDisplay: songsToDisplay)
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
    
    func song(forIndexPath indexPath: IndexPath, songsToDisplay: [Song]) -> Song? {
        if shouldShowPDF() {
            return PDFPageView.songForPageNumber(indexPath.item, allSongs: songsToDisplay)
        } else {
            return SongsManager.songAtIndex(indexPath.row, allSongs: songsToDisplay)
        }
    }
    
    // MARK: - Helpers
    
    func shouldShowPDF() -> Bool {
        if let settings = settings {
            if isLandscape() {
                return settings.shouldShowSheetMusicInLandscape_iPhone
            } else {
                return settings.shouldShowSheetMusicInPortrait_iPhone
            }
        }
        return false
    }
    
    func toolbar() -> UIToolbar? {
        return navigationController?.toolbar
    }
    
    func isLandscape() -> Bool {
        return view.frame.size.width > view.frame.size.height
    }
    
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
            let idx = toolbar()?.items?.firstIndex(of: item)
        {
            toolbar()?.items?.insert(activityIndicatorBarButtonItem, at: idx)
            toolbar()?.items?.remove(at: idx+1)
        }
    }

    func showPlayBarButtonItem() {
        if
            let playBarButtonItem = playBarButtonItem,
            let idx = toolbar()?.items?.firstIndex(of: activityIndicatorBarButtonItem),
            toolbar()?.items?.contains(playBarButtonItem) == false
        {
            toolbar()?.items?.insert(playBarButtonItem, at: idx)
            toolbar()?.items?.remove(at: idx+1)
        }
    }
    
    func showShowPlayerBarButtonItem() {
        if
            let showPlayerBarButtonItem = showPlayerBarButtonItem,
            let idx = toolbar()?.items?.firstIndex(of: activityIndicatorBarButtonItem),
            toolbar()?.items?.contains(showPlayerBarButtonItem) == false
        {
            toolbar()?.items?.insert(showPlayerBarButtonItem, at: idx)
            toolbar()?.items?.remove(at: idx+1)
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
                    if toolbar()?.items?.contains(activityIndicatorBarButtonItem) == false {
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
    
    @IBAction func showSheetMusicTapped(_ sender: Any) {
        if let settings = settings {
            if UIDevice.current.userInterfaceIdiom == .pad {
                settings.shouldShowSheetMusic_iPad = !settings.shouldShowSheetMusic_iPad
            } else {
                if isLandscape() {
                    settings.shouldShowSheetMusicInLandscape_iPhone = !settings.shouldShowSheetMusicInLandscape_iPhone
                } else {
                    settings.shouldShowSheetMusicInPortrait_iPhone = !settings.shouldShowSheetMusicInPortrait_iPhone
                }
            }
            
            collectionView?.reloadData()
            scrollToCurrentSong()
        }
    }
    
    @IBAction func showSettingsTapped(_ sender: Any) {
        if
            let vc = SettingsVC.pfw_instantiateFromStoryboard() as? SettingsVC,
            let app = UIApplication.shared.delegate as? PsalterAppDelegate
        {
            vc.settings = app.settings
            
            vc.modalPresentationStyle = .popover
            
            if let sender = sender as? UIBarButtonItem {
                vc.popoverPresentationController?.barButtonItem = sender
            }
            
            if let pres = vc.presentationController {
                pres.delegate = self
            }
            
            vc.popoverPresentationController?.backgroundColor = vc.view.backgroundColor
            
            vc.preferredContentSize = CGSize(width: 325, height: 246)
            
            present(vc, animated: true, completion: nil)
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
                    toolbar()?.items?.contains(activityIndicatorBarButtonItem) == true && toolbar()?.items?.contains(playBarButtonItem) == false
                {
                    if let currentTrack = playerController.currentTrack {
                        playerController.playTrack(currentTrack, atTime: 0.0, withDelay: 0.0, rate: 1.0)
                    }
                } else if
                    let showPlayerBarButtonItem = showPlayerBarButtonItem,
                    toolbar()?.items?.contains(activityIndicatorBarButtonItem) == true && toolbar()?.items?.contains(showPlayerBarButtonItem) == false
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

extension MetreVC_iPhone: SettingsObserver {
    func settingsDidChange(_ notification: Notification) {
        if let collectionView = collectionView {
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        }
    }
}
