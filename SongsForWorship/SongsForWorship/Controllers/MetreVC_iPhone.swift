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
    var songsToDisplay: [Song]?
    var songsManager: SongsManager?
    var newWindow: UIWindow?
    private var hasScrolled = false
    private var shouldScrollToStartingIndex = false
    
    @IBOutlet private var rotateIconContainerView: UIView!
    @IBOutlet private var rotateIconView: UIView!
    @IBOutlet weak var collectionView: UICollectionView?
    
    private var indexPathOfLastDisplayedCell: IndexPath?
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor(named: "NavBarBackground")
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        navigationController?.navigationBar.compactAppearance = navigationBarAppearance
        navigationController?.navigationBar.standardAppearance = navigationBarAppearance
        
        shouldScrollToStartingIndex = true
        
        configureFavoriteBarButtonItem()
        
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
                    if let number = song?.number {
                        tabBarController?.navigationItem.title = number
                    }
                    songsManager?.setcurrentSong(song, songsToDisplay: songsManager?.songsToDisplay)
                }
            }
            self.indexPathOfLastDisplayedCell = ip
        }
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
                let currentSong = songsManager?.currentSong,
                FavoritesSyncronizer.isFavorite(currentSong)
            {
                return UIImage(named: "heart_filled", in: Helper.songsForWorshipBundle(), with: .none)
            } else {
                return UIImage(named: "heart_outline", in: Helper.songsForWorshipBundle(), with: .none)
            }
        }()
        
        let favoriteBarButtonItem = UIBarButtonItem(image: img, style: .plain, target: self, action: #selector(favoriteBarButtonItemTapped(_:)))
        parent?.navigationItem.rightBarButtonItem = favoriteBarButtonItem
    }
    
    // MARK: - IBActions
    @IBAction func favoriteBarButtonItemTapped(_ sender: Any) {
        if let currentSong = songsManager?.currentSong {
            
            if FavoritesSyncronizer.isFavorite(currentSong) {
                FavoritesSyncronizer.removeFromFavorites(currentSong)
            } else {
                FavoritesSyncronizer.addToFavorites(currentSong)
            }
            
            configureFavoriteBarButtonItem()
        }
    }
    
    // MARK: - Custom getters
}
