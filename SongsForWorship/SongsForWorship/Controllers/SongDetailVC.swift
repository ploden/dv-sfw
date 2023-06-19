//  Converted to Swift 5.1 by Swiftify v5.1.17924 - https://objectivec2swift.com/
//
//  MetreViewController.m
//  PsalmsForWorship
//
//  Created by PHILIP LODEN on 4/28/10.
//  Copyright 2010 Deo Volente, LLC. All rights reserved.
//

import UIKit
import SwiftTheme

enum DisplayMode {
    case singlePageMetre
    case singlePagePDF
    case doublePageAsNeededPDF
}

struct SongDetailItem {
    let indexPath: IndexPath
    let songs: [Song]
    let pdfPageNumbers: PageNumbers?
    let cellID: String
    let displayMode: DisplayMode
}

extension SongDetailItem: Equatable {
    static func == (lhs: SongDetailItem, rhs: SongDetailItem) -> Bool {
        return lhs.indexPath == rhs.indexPath &&
            lhs.songs == rhs.songs &&
            lhs.pdfPageNumbers?.firstPage == rhs.pdfPageNumbers?.firstPage &&
            lhs.pdfPageNumbers?.secondPage == rhs.pdfPageNumbers?.secondPage &&
            lhs.cellID == rhs.cellID &&
            lhs.displayMode == rhs.displayMode
    }
}

class SongDetailVC: UIViewController, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, HasSongsManager, PsalmObserver {
    enum imageNames: String {
        case play = "play.fill", pause = "pause.fill", isFavorite = "bookmark.fill", isNotFavorite = "bookmark", showSheetMusic = "music.note.list", showMetre = "text.alignleft"
    }
    
    weak var delegate: SongDetailVCDelegate?
    @objc func songDidChange(_ notification: Notification) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            if
                let _ = notification.userInfo?[NotificationUserInfoKeys.oldValue] as? Song,
                let new = notification.userInfo?[NotificationUserInfoKeys.newValue] as? Song,
                let songsManager = songsManager,
                let settings = Settings(fromUserDefaults: .standard)
            {
                if playerController?.song != new {
                    playerController?.stopPlaying()
                    playerController = nil
                    
                    if let currentSong = songsManager.currentSong {
                        self.playerController = PlayerController(withSong: currentSong, delegate: self)
                    }
                }
                
                // this feels dangerous
                let newSongDetailItems = SongDetailVC.calculateItems(forSongs: songsManager.songsToDisplay ?? [Song](), appConfig: self.appConfig, settings: settings, displayMode: displayMode(forSize: view.frame.size), isLandscape: isLandscape(forSize: view.frame.size))
                
                if songDetailItems != newSongDetailItems {
                    songDetailItems = newSongDetailItems
                    collectionView?.reloadData()
                }
            }
            scrollToCurrentSong()
            navigationItem.title = songsManager?.currentSong?.number
        }
    }
    var appConfig: AppConfig {
        get {
            let app = UIApplication.shared.delegate as! SFWAppDelegate
            return app.appConfig
        }
    }
    override class var storyboardName: String {
        get {
            return "SongDetail"
        }
    }
    var songsManager: SongsManager? {
        didSet {
            oldValue?.removeObserver(forcurrentSong: self)
            songsManager?.addObserver(forcurrentSong: self)
        }
    }
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
    @IBOutlet private var showSheetMusicBarButtonItem: UIBarButtonItem?
    @IBOutlet weak var collectionView: UICollectionView? {
        didSet {
            if UIDevice.current.userInterfaceIdiom == .pad {
                let tap = UITapGestureRecognizer(target: self, action: #selector(collectionViewTapped))
                collectionView?.addGestureRecognizer(tap)
            }
        }
    }
    private var indexPathOfLastDisplayedCell: IndexPath?
    lazy private var activityIndicatorBarButtonItem: UIBarButtonItem = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.startAnimating()
        return UIBarButtonItem(customView: activityIndicator)
    }()
    var songDetailItems: [SongDetailItem] = [SongDetailItem]()
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = songsManager?.currentSong?.number

        Settings.addObserver(forSettings: self)
        Settings.addObserver(forTheme: self)

        shouldScrollToStartingIndex = true
        
        configureFavoriteBarButtonItem()
        configurePlayerBarButtonItems()
        configureShowSheetMusicBarButtonItem(forSize: view.frame.size)
        
        collectionView?.register(UINib(nibName: String(describing: MetreCVCell.self), bundle: Helper.songsForWorshipBundle()), forCellWithReuseIdentifier: String(describing: MetreCVCell.self))
        collectionView?.register(UINib(nibName: String(describing: SheetMusicCVCell.self), bundle: Helper.songsForWorshipBundle()), forCellWithReuseIdentifier: String(describing: SheetMusicCVCell.self))
        collectionView?.register(UINib(nibName: String(describing: ScrollingSheetMusicCVCell.self), bundle: Helper.songsForWorshipBundle()), forCellWithReuseIdentifier: String(describing: ScrollingSheetMusicCVCell.self))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setToolbarHidden(false, animated: true)

        if
            let isHidden = navigationController?.isNavigationBarHidden,
            isHidden == true
        {
            navigationController?.setNavigationBarHidden(false, animated: false)
            collectionView?.collectionViewLayout.invalidateLayout()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if shouldScrollToStartingIndex {
            if
                let songsToDisplay = songsManager?.songsToDisplay,
                let settings = Settings(fromUserDefaults: .standard),
                songDetailItems.count == 0
            {
                songDetailItems = SongDetailVC.calculateItems(forSongs: songsToDisplay, appConfig: self.appConfig, settings: settings, displayMode: displayMode(forSize: view.frame.size), isLandscape: isLandscape(forSize: view.frame.size))
                collectionView?.reloadData()
            }
            scrollToCurrentSong()
            shouldScrollToStartingIndex = false
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        let animated = true
        
        if view.frame.size.height != size.height && view.frame.size.width == size.width {
            print("viewWillTransition: only heights changed")
        } else if view.frame.size.width != size.width {
            print("viewWillTransition: widths changed")
            
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
                let numItems = collectionView.numberOfItems(inSection: 0)
                
                collectionView.alpha = 0.0
                
                if numItems > 0 {
                    coordinator.animate(alongsideTransition: { context in
                    }) { context in
                        self.songDetailItems = [SongDetailItem]()
                        
                        if
                            let songsToDisplay = self.songsManager?.songsToDisplay,
                            let settings = Settings(fromUserDefaults: .standard),
                            self.songDetailItems.count == 0
                        {
                            self.songDetailItems = SongDetailVC.calculateItems(forSongs: songsToDisplay, appConfig: self.appConfig, settings: settings, displayMode: self.displayMode(forSize: self.view.frame.size), isLandscape: self.isLandscape(forSize: self.view.frame.size))
                        }
                        
                        collectionView.collectionViewLayout.invalidateLayout()
                        collectionView.reloadData()
                        
                        self.scrollToCurrentSong()
                        self.configureShowSheetMusicBarButtonItem(forSize: size)
                        self.navigationItem.title = self.songsManager?.currentSong?.number
                        
                        collectionView.alpha = 1.0
                        
                        UIView.animate(withDuration: 0.15, animations: {
                            collectionView.alpha = 1.0
                        })
                    }
                }
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if let theme = ThemeSetting(rawValue: ThemeManager.currentThemeIndex) {
            switch theme {
            case .defaultLight, .night:
                return .lightContent
            case .white:
                return .darkContent
            }
        }
        return .lightContent
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        (UIApplication.shared.delegate as? SFWAppDelegate)?.changeThemeAsNeeded()
    }
    
    func scrollToCurrentSong() {
        if
            let collectionView = collectionView,
            let current = songsManager?.currentSong,
            let item = songDetailItems.first(where: { $0.songs.contains(current) })
        {
            collectionView.layoutIfNeeded()
            collectionView.scrollToItem(at: item.indexPath, at: .centeredHorizontally, animated: false)
        }
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(playTapped(_:))
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
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
        return songDetailItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let songDetailItem = songDetailItems[indexPath.item]
        
        let cvc = collectionView.dequeueReusableCell(withReuseIdentifier: songDetailItem.cellID, for: indexPath)

        if
            let songsManager = songsManager,
            let songsToDisplay = songsManager.songsToDisplay,
            let song = songDetailItem.songs.first
        {
            if let cvc = cvc as? MetreCVCell {
                cvc.song = song
            } else if let cvc = cvc as? ScrollingSheetMusicCVCell {
                cvc.configure(withPageNumber: songDetailItem.pdfPageNumbers?.firstPage, pdf: song.collection.pdf, allSongs: songsToDisplay, pdfRenderingConfigs: nil, queue: queue)
            } else if let cvc = cvc as? SheetMusicCVCell {
                let renderingConfigs = UIDevice.current.userInterfaceIdiom == .pad ? nil : song.collection.pdfRenderingConfigs_iPhone
                cvc.configure(withPDFPageNumbers: songDetailItem.pdfPageNumbers, pdf: song.collection.pdf, allSongs: songsToDisplay, pdfRenderingConfigs: renderingConfigs, queue: queue)
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
                let songsToDisplay = songsManager?.songsToDisplay,
                ip.item < songDetailItems.count
            {
                if !(navigationItem.title != nil) || indexPathOfLastDisplayedCell?.compare(ip) != .orderedSame {
                    let song = songDetailItems[ip.item].songs.first
                    songsManager?.removeObserver(forcurrentSong: self)
                    songsManager?.setcurrentSong(song, songsToDisplay: songsToDisplay)
                    songsManager?.addObserver(forcurrentSong: self)
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
    
    // MARK: - Helpers
    
    func currentlyVisibleSongs() -> [Song] {
        if let collectionView = collectionView {
            let center = collectionView.convert(collectionView.center, from: collectionView.superview)
            let ip = collectionView.indexPathForItem(at: center)
            
            if
                let ip = ip,
                ip.item < songDetailItems.count
            {
                return songDetailItems[ip.item].songs
            }
        }
        return [Song]()
    }
    
    class func calculateItems(forSongs songs: [Song], appConfig: AppConfig, settings: Settings, displayMode: DisplayMode, isLandscape: Bool) -> [SongDetailItem] {
        // single page metre
        // single page pdf with possible metre
        // double page as needed with possible metre
        switch displayMode {
        case .singlePageMetre:
            // single page metre
            var idx = 0
            
            let items: [SongDetailItem] = songs.map {
                let indexPath = IndexPath(item: idx, section: 0)
                idx += 1
                let cellID = String(describing: MetreCVCell.self)
                return SongDetailItem(indexPath: indexPath, songs: [$0], pdfPageNumbers: nil, cellID: cellID, displayMode: .singlePageMetre)
            }
                
            return items
        case .singlePagePDF:
            var items = [SongDetailItem]()

            var idx = 0
            
            for song in songs {
                if appConfig.shouldHideSheetMusicForCopyrightedTunes && song.isTuneCopyrighted {
                    let indexPath = IndexPath(item: idx, section: 0)
                    idx += 1
                    let cellID = String(describing: MetreCVCell.self)
                    let item = SongDetailItem(indexPath: indexPath, songs: [song], pdfPageNumbers: nil, cellID: cellID, displayMode: .singlePageMetre)
                    items.append(item)
                } else {
                    let cellID: String = {
                        if UIDevice.current.userInterfaceIdiom == .pad {
                            return String(describing: SheetMusicCVCell.self)
                        } else {
                            return String(describing: isLandscape ? ScrollingSheetMusicCVCell.self : SheetMusicCVCell.self)
                        }
                    }()
                    
                    for pdfPageNumber in song.pdfPageNumbers {
                        if
                            let previousItem = items.last,
                            previousItem.pdfPageNumbers?.firstPage == pdfPageNumber
                        {
                            items.removeLast()
                            let newPreviousItem = SongDetailItem(indexPath: previousItem.indexPath, songs: previousItem.songs + [song], pdfPageNumbers: previousItem.pdfPageNumbers, cellID: previousItem.cellID, displayMode: .singlePagePDF)
                            items.append(newPreviousItem)
                        } else {
                            let indexPath = IndexPath(item: idx, section: 0)
                            idx += 1
                            let item = SongDetailItem(indexPath: indexPath, songs: [song], pdfPageNumbers: PageNumbers(firstPage: pdfPageNumber, secondPage: nil) , cellID: cellID, displayMode: .singlePagePDF)
                            items.append(item)
                        }
                    }
                }
            }
            
            return items
        case .doublePageAsNeededPDF:
            var items = [SongDetailItem]()

            var idx = 0
            
            for song in songs {
                if appConfig.shouldHideSheetMusicForCopyrightedTunes && song.isTuneCopyrighted {
                    let indexPath = IndexPath(item: idx, section: 0)
                    idx += 1
                    let cellID = String(describing: MetreCVCell.self)
                    let item = SongDetailItem(indexPath: indexPath, songs: [song], pdfPageNumbers: nil, cellID: cellID, displayMode: .singlePageMetre)
                    items.append(item)
                } else {
                    let cellID = String(describing: SheetMusicCVCell.self)
                    
                    if song.pdfPageNumbers.count > 1 {
                        // potential double page
                        var pdfPageNumberIdx = 0
                        
                        while pdfPageNumberIdx < song.pdfPageNumbers.count {
                            let pdfPageNumber = song.pdfPageNumbers[pdfPageNumberIdx]
                            
                            if
                                let previousItem = items.last,
                                previousItem.pdfPageNumbers?.firstPage == pdfPageNumber || previousItem.pdfPageNumbers?.secondPage == pdfPageNumber
                            {
                                items.removeLast()
                                let newPreviousItem = SongDetailItem(indexPath: previousItem.indexPath, songs: previousItem.songs + [song], pdfPageNumbers: previousItem.pdfPageNumbers, cellID: previousItem.cellID, displayMode: .singlePagePDF)
                                items.append(newPreviousItem)
                                
                                pdfPageNumberIdx += 1
                            } else {
                                let indexPath = IndexPath(item: idx, section: 0)
                                idx += 1
                                
                                var secondPDFPageNumber: Int? = nil
                                
                                if pdfPageNumberIdx + 1 < song.pdfPageNumbers.count {
                                    secondPDFPageNumber = song.pdfPageNumbers[pdfPageNumberIdx + 1]
                                    pdfPageNumberIdx += 2
                                } else {
                                    pdfPageNumberIdx += 1
                                }
                                
                                let item = SongDetailItem(indexPath: indexPath, songs: [song], pdfPageNumbers: PageNumbers(firstPage: pdfPageNumber, secondPage: secondPDFPageNumber) , cellID: cellID, displayMode: .doublePageAsNeededPDF)
                                items.append(item)
                            }
                        }
                    } else {
                        // single page
                        for pdfPageNumber in song.pdfPageNumbers {
                            if
                                let previousItem = items.last,
                                previousItem.pdfPageNumbers?.firstPage == pdfPageNumber
                            {
                                items.removeLast()
                                let newPreviousItem = SongDetailItem(indexPath: previousItem.indexPath, songs: previousItem.songs + [song], pdfPageNumbers: previousItem.pdfPageNumbers, cellID: previousItem.cellID, displayMode: .singlePagePDF)
                                items.append(newPreviousItem)
                            } else {
                                let indexPath = IndexPath(item: idx, section: 0)
                                idx += 1
                                let item = SongDetailItem(indexPath: indexPath, songs: [song], pdfPageNumbers: PageNumbers(firstPage: pdfPageNumber, secondPage: nil) , cellID: cellID, displayMode: .singlePagePDF)
                                items.append(item)
                            }
                        }
                    }
                }
            }
            
            return items
        }
        
    }
    
    func displayMode(forSize size: CGSize) -> DisplayMode {
        if UIDevice.current.userInterfaceIdiom == .pad {
            if shouldShowPDF(forSize: size) {
                if isLandscape(forSize: size) {
                    return .doublePageAsNeededPDF
                } else {
                    return .singlePagePDF
                }
            } else {
                return .singlePageMetre
            }
        } else {
            if shouldShowPDF(forSize: size) {
                return .singlePagePDF
            } else {
                return .singlePageMetre
            }
        }
    }
    
    func shouldShowPDF(forSize size: CGSize) -> Bool {
        if let settings = Settings(fromUserDefaults: .standard) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return settings.shouldShowSheetMusic_iPad
            } else {
                if isLandscape(forSize: view.frame.size) {
                    return settings.shouldShowSheetMusicInLandscape_iPhone
                } else {
                    return settings.shouldShowSheetMusicInPortrait_iPhone
                }
            }
        }
        return false
    }
    
    func toolbar() -> UIToolbar? {
        return navigationController?.toolbar
    }
    
    func isLandscape(forSize size: CGSize) -> Bool {
        return size.width > size.height
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
    
    func configureShowSheetMusicBarButtonItem(forSize size: CGSize) {
        let img: UIImage? = {
            if shouldShowPDF(forSize: size) {
                return UIImage(systemName: imageNames.showMetre.rawValue)
            } else {
                return UIImage(systemName: imageNames.showSheetMusic.rawValue)
            }
        }()
        
        showSheetMusicBarButtonItem?.image = img
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
    
    @IBAction func collectionViewTapped(_ sender: Any) {
        if
            let splitViewController = splitViewController,
            view.frame.size.width > view.frame.size.height
        {
            // only do if landscape
            if splitViewController.displayMode == .secondaryOnly {
                splitViewController.show(.primary)
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                self.navigationController?.setToolbarHidden(false, animated: true)
            } else {
                splitViewController.hide(.primary)
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                self.navigationController?.setToolbarHidden(true, animated: true)
            }
        } else {
            if let navigationController = navigationController {
                navigationController.setNavigationBarHidden(!navigationController.isNavigationBarHidden, animated: true)
                navigationController.setToolbarHidden(!navigationController.isToolbarHidden, animated: true)
                
                UIView.transition(with: self.view, duration: TimeInterval(UINavigationController.hideShowBarDuration), options: .curveEaseInOut) {
                    if let collectionView = self.collectionView {
                        collectionView.visibleCells.forEach { $0.setNeedsDisplay() }
                    }
                } completion: { (finished) in }
            }
        }
    }
    
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
    
    func playCurrentSong() {
        if
            let songsManager = songsManager,
            let currentSong = songsManager.currentSong
        {
            if playerController == nil || playerController?.song != currentSong {
                self.playerController = PlayerController(withSong: currentSong, delegate: self)
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
    }
    
    @IBAction func playTapped(_ sender: Any) {
        let currentlyVisible = currentlyVisibleSongs()
        
        if currentlyVisible.count > 1 {
            if let playerController = playerController {
                if playerController.isPlaying() {
                    playerController.pause()
                } else if playerController.isPaused {
                    playerController.resume()
                } else {
                    if let playBarButtonItem = playBarButtonItem {
                        showSelectSongVC(withSongs: currentlyVisible, fromBarButtonItem: playBarButtonItem)
                    }
                }
            }
        } else {
            playCurrentSong()
        }
    }
    
    func showSelectSongVC(withSongs songs: [Song], fromBarButtonItem barButtonItem: UIBarButtonItem) {
        if let vc = SelectSongMenuVC.pfw_instantiateFromStoryboard() as? SelectSongMenuVC {
            vc.songs = songs
            vc.delegate = self
            vc.modalPresentationStyle = .popover
            vc.popoverPresentationController?.barButtonItem = barButtonItem
            if let pres = vc.presentationController {
                pres.delegate = self
            }
            vc.popoverPresentationController?.backgroundColor = vc.view.backgroundColor
            let buttonHeight = 30.0
            vc.preferredContentSize = CGSize(width: Double(songs.count) * buttonHeight * 2, height: buttonHeight)
            present(vc, animated: true, completion: nil)
        }
    }
    
    func showPlayerForCurrentSong() {
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
    
    @IBAction func showPlayerTapped(_ sender: Any) {
        let currentlyVisible = currentlyVisibleSongs()
        
        if currentlyVisible.count > 1 {
            if
                let playerController = playerController,
                playerController.isPlaying()
            {
                showPlayerForCurrentSong()
            } else {
                if let showPlayerBarButtonItem = showPlayerBarButtonItem {
                    showSelectSongVC(withSongs: currentlyVisible, fromBarButtonItem: showPlayerBarButtonItem)
                }
            }
        } else {
            showPlayerForCurrentSong()
        }
    }
    
    @IBAction func showSheetMusicTapped(_ sender: Any) {
        if let settings = Settings(fromUserDefaults: .standard) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                _ = settings.new(withShouldShowSheetMusic_iPad: !settings.shouldShowSheetMusic_iPad).save(toUserDefaults: .standard)
            } else {
                if isLandscape(forSize: view.frame.size) {
                    _ = settings.new(withShouldShowSheetMusicInLandscape_iPhone: !settings.shouldShowSheetMusicInLandscape_iPhone).save(toUserDefaults: .standard)
                } else {
                    _ = settings.new(withShouldShowSheetMusicInPortrait_iPhone: !settings.shouldShowSheetMusicInPortrait_iPhone).save(toUserDefaults: .standard)                    
                }
            }
            
            if let songsToDisplay = songsManager?.songsToDisplay {
                songDetailItems = SongDetailVC.calculateItems(forSongs: songsToDisplay, appConfig: self.appConfig, settings: settings, displayMode: displayMode(forSize: view.frame.size), isLandscape: isLandscape(forSize: view.frame.size))
                collectionView?.reloadData()
                scrollToCurrentSong()
                navigationItem.title = songsManager?.currentSong?.number
            }
            
            configureShowSheetMusicBarButtonItem(forSize: view.frame.size)
        }
    }
    
    @IBAction func showSettingsTapped(_ sender: Any) {
        if let vc = SettingsVC.pfw_instantiateFromStoryboard() as? SettingsVC {
            vc.modalPresentationStyle = .popover
            
            if let sender = sender as? UIBarButtonItem {
                vc.popoverPresentationController?.barButtonItem = sender
            }
            
            if let pres = vc.presentationController {
                pres.delegate = self
            }
            
            vc.popoverPresentationController?.backgroundColor = vc.view.backgroundColor
            
            vc.preferredContentSize = CGSize(width: 325, height: 251
            )
            
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
        
        tunesVC.preferredContentSize = CGSize(width: 375, height: 172)
        
        present(tunesVC, animated: true, completion: nil)
    }
    
    // MARK: - Custom getters
}

extension SongDetailVC: UIPopoverPresentationControllerDelegate {
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

extension SongDetailVC: PlayerControllerDelegate {
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

extension SongDetailVC: SettingsObserver {
    func settingsDidChange(_ notification: Notification) {
        if let collectionView = collectionView {
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        }
    }
}

extension SongDetailVC: ThemeObserver {
    func themeDidChange(_ notification: Notification) {
        if let collectionView = collectionView {
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        }
    }
}

extension SongDetailVC: SelectSongMenuVCDelegate {
    func selectSongMenuVC(selectSongMenuVC: SelectSongMenuVC?, didSelectSong selectedSong: Song) {
        let presentingItem = selectSongMenuVC?.popoverPresentationController?.barButtonItem
        selectSongMenuVC?.dismiss(animated: true, completion: nil)
        selectSongMenuVC?.delegate = nil // disconnect ASAP
        
        if
            let presentingItem = presentingItem,
            let songsManager = songsManager
        {
            if presentingItem == self.playBarButtonItem {
                songsManager.removeObserver(forcurrentSong: self)
                songsManager.setcurrentSong(selectedSong, songsToDisplay: songsManager.songsToDisplay)
                songsManager.addObserver(forcurrentSong: self)
                playCurrentSong()
            } else if presentingItem == self.showPlayerBarButtonItem {
                songsManager.removeObserver(forcurrentSong: self)
                songsManager.setcurrentSong(selectedSong, songsToDisplay: songsManager.songsToDisplay)
                songsManager.addObserver(forcurrentSong: self)
                showPlayerForCurrentSong()
            }
        }
    }
}
