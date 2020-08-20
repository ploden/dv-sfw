//
//  DetailVC.m
//  justipad
//
//  Created by PHILIP LODEN on 10/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

import UIKit

private var kIsFavoriteText = "\u{2605}"
private var kIsNotFavoriteText = "\u{2606}"

class DetailVC: UIViewController, UIPopoverControllerDelegate, UISplitViewControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PsalmObserver {
    var songsManager: SongsManager?
    var tunesButtonImage: UIImage?
    weak var delegate: DetailVCDelegate?
    private var isObservingcurrentSong = false
    
    private var tunesVC: TunesVC?
    private var splitVCBarButtonItem: UIBarButtonItem?
    @IBOutlet private var statusBarBackgroundView: UIView!
    @IBOutlet weak private var backgroundView: UIView?
    @IBOutlet weak var favoriteBarButtonItem: UIBarButtonItem?
    @IBOutlet weak var tunesBarButtonItem: UIBarButtonItem?
    @IBOutlet weak var collectionView: UICollectionView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        songsManager?.addObserver(forcurrentSong: self)
        isObservingcurrentSong = true
        
        let navbarLogo = UIImageView(image: UIImage(named: "nav_bar_icon", in: Helper.songsForWorshipBundle(), with: .none))
        var frameRect = navbarLogo.frame
        frameRect.origin.x = 30
        navbarLogo.frame = frameRect
        navigationItem.titleView = navbarLogo
        
        if let app = UIApplication.shared.delegate as? PsalterAppDelegate {
            let nav = app.navigationController
            nav?.delegate = self
        }
        
        let metreClassStr = "MetreCVCell"
        collectionView?.register(UINib(nibName: metreClassStr, bundle: Helper.songsForWorshipBundle()), forCellWithReuseIdentifier: metreClassStr)
        
        let logoClassStr = "LogoCVCell"
        collectionView?.register(UINib(nibName: logoClassStr, bundle: Helper.songsForWorshipBundle()), forCellWithReuseIdentifier: logoClassStr)
        
        let musicClassStr = "SheetMusicCVCell"
        collectionView?.register(UINib(nibName: musicClassStr, bundle: Helper.songsForWorshipBundle()), forCellWithReuseIdentifier: musicClassStr)
        
        NotificationCenter.default.addObserver(self, selector: #selector(configureFavoritesBarButtonItemTitle), name: NSNotification.Name.favoritesDidChange, object: nil)
        
        if (parent is UISplitViewController) {
            let split = parent as? UISplitViewController
            split?.delegate = self
        }
        
        collectionView?.contentInset = .zero
        collectionView?.contentOffset = CGPoint.zero
        collectionView?.layoutMargins = .zero
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
                
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
    
    // MARK: - IBActions
    @IBAction func tunesButtonTouched(_ sender: Any) {
        if let tunesVC = tunesVC {
            guard tunesVC.presentingViewController != nil else {
                tunesVC.popoverPresentationController?.barButtonItem = tunesBarButtonItem
                present(tunesVC, animated: true, completion: nil)
                return
            }
        } else if let tunesVC = TunesVC.pfw_instantiateFromStoryboard() as? TunesVC {
            tunesVC.songsManager = songsManager
            tunesVC.modalPresentationStyle = .popover
            tunesVC.popoverPresentationController?.barButtonItem = tunesBarButtonItem
            present(tunesVC, animated: true, completion: nil)
            self.tunesVC = tunesVC
        }
    }
    
    @IBAction func favoriteButtonTapped(_ sender: Any) {
        if let currentSong = songsManager?.currentSong {
            
            if FavoritesSyncronizer.isFavorite(currentSong) {
                FavoritesSyncronizer.removeFromFavorites(currentSong)
            } else {
                FavoritesSyncronizer.addToFavorites(currentSong)
            }
            
            configureFavoritesBarButtonItemTitle()
        }
    }
    
    // MARK: - Helper methods
    func songsToDisplay() -> [Song]? {
        return delegate?.songsToDisplayForDetailVC(self)
    }
    
    func songDidChange(_ didScroll: Bool) {
        configureFavoritesBarButtonItemTitle()
                
        tunesButtonImageChange()
        tunesVC = nil
        
        if let app = UIApplication.shared.delegate as? PsalterAppDelegate {
            let nav = app.navigationController
            nav?.delegate = self
        }
        
        var pageNum = 0
        
        if
            let current = songsManager?.currentSong,
            let collectionView = collectionView,
            let songsToDisplay = songsToDisplay()
        {
            pageNum = PDFPageView.pageNumberForPsalm(current, allSongs: songsToDisplay, idx: nil)
            
            if collectionView.numberOfItems(inSection: 0) == 1 || songsToDisplay.count != collectionView.numberOfItems(inSection: 0) {
                collectionView.reloadData()
            }
            
            if pageNum < collectionView.numberOfItems(inSection: 0) {
                collectionView.scrollToItem(at: IndexPath(item: pageNum, section: 0), at: [], animated: false)
            }
        }
    }
    
    func tunesButtonImageChange() {
        if let aSong = songsManager?.currentSong {
            if aSong.isTuneCopyrighted == true {
                tunesButtonImage = UIImage(named: "no_tunes_icon", in: Helper.songsForWorshipBundle(), with: .none)
                tunesBarButtonItem?.isEnabled = false
            } else {
                tunesButtonImage = UIImage(named: "tunes_icon", in: Helper.songsForWorshipBundle(), with: .none)
                tunesBarButtonItem?.isEnabled = true
            }
        } else {
            tunesButtonImage = UIImage(named: "tunes_icon", in: Helper.songsForWorshipBundle(), with: .none)
            tunesBarButtonItem?.isEnabled = true
        }
    }
    
    @objc func configureFavoritesBarButtonItemTitle() {
        let img: UIImage? = {
            if
                let currentSong = songsManager?.currentSong,
                FavoritesSyncronizer.isFavorite(currentSong)
            {
                return UIImage(named: "heart_filled", in: Helper.songsForWorshipBundle(), with: .none)
            } else {
                return UIImage(named: "heart_outline", in: Helper.songsForWorshipBundle(), with: .none)
            }
        }()
        
        favoriteBarButtonItem?.image = img
    }
    
    // MARK: - Split view support
    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) {
        
    }
    
    // MARK: - Rotation support
    func shouldAutorotate() -> Bool {
        return true
    }
    
    func songDidChange(_ notification: Notification) {
        if
            let object = notification.object as? SongsManager,
            object == songsManager
        {
            songDidChange(false)
        }
    }
    
    deinit {
        if isObservingcurrentSong {
            songsManager?.removeObserver(forcurrentSong: self)
        }
    }
    
    // MARK: - UIScrollView
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let collectionView = collectionView {
            let center = collectionView.convert(collectionView.center, from: collectionView.superview)
            let ip = collectionView.indexPathForItem(at: center)
            
            if
                let pageNumber = ip?.item,
                let songsToDisplay = songsToDisplay(),
                let currentSong = songsManager?.currentSong
            {
                let song = PDFPageView.songForPageNumber(pageNumber, allSongs: songsToDisplay)
                
                if song != currentSong {
                    songsManager?.removeObserver(forcurrentSong: self)
                    songsManager?.setcurrentSong(song, songsToDisplay: songsToDisplay)
                    configureFavoritesBarButtonItemTitle()
                    tunesButtonImageChange()
                    songsManager?.addObserver(forcurrentSong: self)
                }
            }
        }
    }
    
    // MARK: - collection view
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (songsManager?.currentSong) != nil {
            return PDFPageView.numberOfPages(songsToDisplay())
        } else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 && songsManager?.currentSong == nil {
            let cvc = collectionView.dequeueReusableCell(withReuseIdentifier: "LogoCVCell", for: indexPath) as? LogoCVCell
            return cvc!
        } else {
            if
                let songsToDisplay = songsToDisplay(),
                let song = PDFPageView.songForPageNumber(indexPath.row, allSongs: songsToDisplay)
            {
                if (song.isTuneCopyrighted) {
                    let cvc = collectionView.dequeueReusableCell(withReuseIdentifier: "MetreCVCell", for: indexPath) as? MetreCVCell
                    cvc?.song = song
                    return cvc!
                } else {
                    let cvc = collectionView.dequeueReusableCell(withReuseIdentifier: "SheetMusicCVCell", for: indexPath) as? SheetMusicCVCell
                    if let songsManager = songsManager {
                        cvc?.configureWithPageNumber(indexPath.item, allSongs: songsToDisplay, songsManager: songsManager)
                    }
                    return cvc!
                }
            }
        }
        
        return UICollectionViewCell()
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
}