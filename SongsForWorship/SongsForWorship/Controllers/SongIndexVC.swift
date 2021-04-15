//
//  PsalmIndexVC.swift
//  PsalmsForWorship
//
//  Created by PHILIP LODEN on 4/17/10.
//  Copyright 2010 Deo Volente, LLC. All rights reserved.
//

import UIKit

class SongIndexVC: UIViewController, HasSongsManager, SongDetailVCDelegate, UITableViewDelegate, UITableViewDataSource, PsalmObserver, SongCollectionObserver {
    
    private var firstTime: Bool = false
    private var isPerformingSearch = false
    private var isObservingcurrentSong = false
    
    var songsManager: SongsManager?
    @IBOutlet weak var songIndexTableView: UITableView?
    @IBOutlet private var copyrightTVCell: UITableViewCell!
    private var previewingContext: UIViewControllerPreviewing?
    private var segmentedControl: UISegmentedControl?
    private var searchTableViewController: SearchTableViewController?
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = ""
        configureNavBar()
        
        if UIDevice.current.userInterfaceIdiom != .pad {
            let interaction = UIContextMenuInteraction(delegate: self)
            songIndexTableView?.addInteraction(interaction)
        }

        songIndexTableView?.rowHeight = UITableView.automaticDimension
        songIndexTableView?.estimatedRowHeight = 50.0
        songIndexTableView?.register(UINib(nibName: "GenericTVCell", bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: "GenericTVCell")
        songIndexTableView?.register(UINib(nibName: "SongTVCell", bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: "SongTVCell")
        
        if
            let songsManager = songsManager,
            songsManager.songCollections.count > 1
        {
            segmentedControl = UISegmentedControl(items: songsManager.songCollections.map { $0.displayName } )
            segmentedControl?.addTarget(self, action: #selector(self.segmentedControlValueChanged(_:)), for: .valueChanged)
            let idx = 2
            
            if let segmentedControl = segmentedControl {
                toolbarItems?.insert(UIBarButtonItem(customView: segmentedControl), at: idx)
            }
            
            toolbarItems?.insert(UIBarButtonItem.flexibleSpace(), at: idx)
            segmentedControl?.selectedSegmentIndex = 0
        }
        
        firstTime = true
        songsManager?.addObserver(forcurrentSong: self)
        songsManager?.addObserver(forSelectedCollection: self)
        isObservingcurrentSong = true
        
        definesPresentationContext = true
        
        Settings.addObserver(forSettings: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setToolbarHidden(false, animated: animated)
        navigationController?.toolbar.isTranslucent = false
        
        if UIDevice.current.userInterfaceIdiom != .pad {
            NotificationCenter.default.post(name: NSNotification.Name("stop playing"), object: nil)
        }
        
        let currentSongIndexPath: IndexPath? = {
            var ip: IndexPath?
            
            if
                let songsManager = self.songsManager,
                let currentSong = songsManager.currentSong
            {
                ip = self.indexPathForIndex(currentSong.index)
            }
            
            return ip
        }()
        
        let selectedRowIndexPath = songIndexTableView?.indexPathForSelectedRow
        
        if
            let currentSongIndexPath = currentSongIndexPath,
            selectedRowIndexPath != nil && currentSongIndexPath != selectedRowIndexPath
        {
            songIndexTableView?.selectRow(at: currentSongIndexPath, animated: false, scrollPosition: .middle)
            songIndexTableView?.scrollToNearestSelectedRow(at: .middle, animated: false)
        }                
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UIDevice.current.userInterfaceIdiom != .pad {
            let selection = songIndexTableView?.indexPathForSelectedRow
            if selection != nil {
                if let selection = selection {
                    songIndexTableView?.deselectRow(at: selection, animated: true)
                }
            }
        }
    }
    
    // MARK: - Rotation Methods
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .all
        } else {
            return .portrait
        }
    }
    
    override var shouldAutorotate: Bool {
        if UIDevice.current.userInterfaceIdiom == .pad || !UIDevice.current.orientation.isLandscape {
            return true
        } else {
            return false
        }
    }
    
    // MARK: - UITableView Delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        if let count = selectedSongCollection()?.sections.count {
            return count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if let sections = selectedSongCollection()?.sections {
            return sections.map { $0.title }
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if
            let sections = selectedSongCollection()?.sections,
            section < sections.count
        {
            let collectionSection = sections[section]
            return collectionSection.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isCopyrightTVCell(indexPath) {
            let tvc = songIndexTableView?.dequeueReusableCell(withIdentifier: "GenericTVCell") as? GenericTVCell
            tvc?.textLabel?.text = Helper.copyrightString(nil)
            tvc?.textLabel?.textAlignment = .center
            tvc?.textLabel?.font = Helper.defaultFont(withSize: 9.0, forTextStyle: .body)
            tvc?.textLabel?.numberOfLines = 2
            tvc?.textLabel?.textColor = UIColor(red: 80.0 / 256.0, green: 80.0 / 256.0, blue: 80.0 / 256.0, alpha: 1.0)
            tvc?.selectionStyle = .none
            return tvc!
        } else {
            let song = self.songForIndexPath(indexPath)
            
            let songCell = tableView.dequeueReusableCell(withIdentifier: "SongTVCell") as? SongTVCell
            songCell?.configureWithPsalm(song, isFavorite: false)
            return songCell!
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isCopyrightTVCell(indexPath) == false {
            let song = self.songForIndexPath(indexPath)
            
            songsManager?.setcurrentSong(song, songsToDisplay: song?.collection.songs)
            
            if let vc = SongDetailVC.pfw_instantiateFromStoryboard() as? SongDetailVC {
                vc.songsManager = songsManager
                if UIDevice.current.userInterfaceIdiom != .pad {
                    self.navigationController?.pushViewController(vc, animated: true)
                } else if
                    let detail = splitViewController?.viewController(for: .secondary),
                    !(detail is SongDetailVC) == true
                {
                    if let detailNav = detail.navigationController {
                        detailNav.setViewControllers([vc], animated: false)
                    }
                }
            }
        }
    }
    
    // MARK: - helper methods
    
    func configureNavBar() {
        print("SongIndexVC: configureNavBar")
        
        if let settings = Settings(fromUserDefaults: .standard) {
            if settings.calculateTheme(forUserInterfaceStyle: traitCollection.userInterfaceStyle) == .defaultLight {
                let navbarLogo = UIImageView(image: UIImage(named: "nav_bar_icon", in: nil, with: .none))
                navigationItem.titleView = navbarLogo
            } else if settings.calculateTheme(forUserInterfaceStyle: traitCollection.userInterfaceStyle) == .white {
                let templateImage = UIImage(named: "nav_bar_icon", in: nil, with: .none)!.withRenderingMode(.alwaysTemplate)
                let navbarLogo = UIImageView(image: templateImage)
                navbarLogo.tintColor = UIColor(named: "NavBarBackground")!
                navigationItem.titleView = navbarLogo
            }  else if settings.calculateTheme(forUserInterfaceStyle: traitCollection.userInterfaceStyle) == .night {
                let templateImage = UIImage(named: "nav_bar_icon", in: nil, with: .none)!.withRenderingMode(.alwaysTemplate)
                let navbarLogo = UIImageView(image: templateImage)
                navbarLogo.tintColor = .white
                navigationItem.titleView = navbarLogo
            }
        }
    }
    
    func selectedSongCollection() -> SongCollection? {
        if let segmentedControl = segmentedControl {
            return songsManager?.songCollections[segmentedControl.selectedSegmentIndex]
        }
        return songsManager?.songCollections.first
    }
    
    func isCopyrightTVCell(_ indexPath: IndexPath?) -> Bool {
        return false
    }
    
    func indexForIndexPath(_ indexPath: IndexPath) -> Int {
        var count = 0
        if let songIndexTableView = songIndexTableView {
            for i in 0..<indexPath.section {
                count += songIndexTableView.numberOfRows(inSection: i)
            }
        }
        return count + indexPath.row
    }
    
    func indexPathForIndex(_ index: Int) -> IndexPath? {
        if let songIndexTableView = songIndexTableView {
            var count = 0
            var sectionIdx = 0
            
            for idx in 0..<songIndexTableView.numberOfSections {
                sectionIdx = idx
                let numRows = songIndexTableView.numberOfRows(inSection: idx)
                if (count + numRows) > index {
                    break
                } else {
                    count += numRows
                }
            }
            
            return IndexPath(row: index - count, section: sectionIdx)
        }
        return nil
    }
    
    func songForIndexPath(_ indexPath: IndexPath?) -> Song? {
        var song: Song?
        
        if
            let songsArray = selectedSongCollection()?.songs,
            let indexPath = indexPath
        {
            song = songsArray[indexForIndexPath(indexPath)]
        }
        
        return song
    }
    
    @objc func songDidChange(_ notification: Notification) {
        if
            let object = notification.object as? SongsManager,
            object == songsManager
        {
            let currentSongIndexPath: IndexPath? = {
                var ip: IndexPath?
                
                if
                    let songsManager = songsManager,
                    let current = songsManager.currentSong
                {
                    ip = self.indexPathForIndex(current.index)
                }
                
                return ip
            }()
            
            let selectedRowIndexPath = songIndexTableView?.indexPathForSelectedRow
            
            if
                UIDevice.current.userInterfaceIdiom == .pad,
                let selectedRowIndexPath = selectedRowIndexPath,
                currentSongIndexPath != selectedRowIndexPath
            {
                songIndexTableView?.selectRow(at: currentSongIndexPath, animated: true, scrollPosition: .none)
                
                let selectedRowIndexPath = songIndexTableView?.indexPathForSelectedRow
                
                if let selectedRowIndexPath = selectedRowIndexPath {
                    if !(songIndexTableView?.indexPathsForVisibleRows?.contains(selectedRowIndexPath) ?? false) {
                        songIndexTableView?.scrollToNearestSelectedRow(at: .middle, animated: true)
                    }
                }
            }
        }
    }
    
    deinit {
        if isObservingcurrentSong {
            songsManager?.removeObserver(forcurrentSong: self)
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - DetailVCDelegate
    
    func songsToDisplayForDetailVC(_ detailVC: SongDetailVC?) -> [Song]? {
        return songsManager?.currentSong?.collection.songs
    }
    
    func isSearchingForDetailVC(_ detailVC: SongDetailVC?) -> Bool {
        return false
    }
    
    // MARK: - IBActions
    
    @IBAction func segmentedControlValueChanged(_ sender: Any) {
        songIndexTableView?.reloadData()
        songIndexTableView?.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
    }
    
    func selectedCollectionDidChange(_ notification: Notification) {
        songIndexTableView?.reloadData()
    }
    
    @IBAction func searchTapped(_ sender: Any) {
        if searchTableViewController == nil {
            searchTableViewController = SearchTableViewController.pfw_instantiateFromStoryboard() as? SearchTableViewController
        }
        
        if let searchTableViewController = self.searchTableViewController {
            searchTableViewController.songsManager = songsManager
            searchTableViewController.delegate = self
            let nc = UINavigationController(rootViewController: searchTableViewController)
            present(nc, animated: true, completion: nil)
        }
    }
    
    @IBAction func favoritesTapped(_ sender: Any) {
        if let vc = FavoritesVC.pfw_instantiateFromStoryboard() as? FavoritesVC {
            vc.songsManager = songsManager
            vc.delegate = self
            let nc = UINavigationController(rootViewController: vc)            
            present(nc, animated: true, completion: nil)
        }
    }
}

extension SongIndexVC: FavoritesTableViewControllerDelegate {
    func favoritesTableViewController(didSelectFavorite song: Song) {
        if
            let detail = splitViewController?.viewController(for: .secondary),
            !(detail is SongDetailVC) == true
        {
            if let vc = SongDetailVC.pfw_instantiateFromStoryboard() as? SongDetailVC {
                vc.songsManager = songsManager
                if let detailNav = detail.navigationController {
                    detailNav.setViewControllers([vc], animated: false)
                }
            }
        }
        
        songsManager?.setcurrentSong(song, songsToDisplay: song.collection.songs)
        
        if UIDevice.current.userInterfaceIdiom != .pad {
            if let vc = SongDetailVC.pfw_instantiateFromStoryboard() as? SongDetailVC {
                vc.songsManager = songsManager
                
                if
                    let segmentedControl = segmentedControl,
                    let idx = songsManager?.songCollections.firstIndex(of: song.collection)
                {
                    segmentedControl.selectedSegmentIndex = idx
                    songIndexTableView?.reloadData()
                    let ip = indexPathForIndex(song.index)
                    
                    if let ip = ip {
                        songIndexTableView?.scrollToRow(at: ip, at: .middle, animated: false)
                    }
                }
                
                dismiss(animated: true)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            if
                let segmentedControl = segmentedControl,
                let idx = songsManager?.songCollections.firstIndex(of: song.collection)
            {
                segmentedControl.selectedSegmentIndex = idx
                songIndexTableView?.reloadData()
                let ip = indexPathForIndex(song.index)
                
                if let ip = ip {
                    songIndexTableView?.scrollToRow(at: ip, at: .middle, animated: false)
                }
            }
            dismiss(animated: true, completion: nil)
        }
    }
}

extension SongIndexVC: SettingsObserver {
    func settingsDidChange(_ notification: Notification) {
        if let songIndexTableView = songIndexTableView {
            songIndexTableView.reloadData()
        }
        configureNavBar()
    }
}

extension SongIndexVC: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let configuration = UIContextMenuConfiguration(
            identifier: "SongPreviewIdentifier" as NSCopying,
            previewProvider: {
                let newPoint = self.view.convert(location, to: self.songIndexTableView)
                let index = self.songIndexTableView?.indexPathForRow(at: newPoint)
 
                if
                    let index = index,
                    let song = self.songForIndexPath(index)
                {
                    return SongPreviewViewController(withPsalm: song)
                }
                return nil
            },
            actionProvider: { suggestedActions in
                // Return a UIMenu or nil
                return nil
            }
        )
        
        return configuration
    }
}

extension SongIndexVC: SearchTableViewControllerDelegate {
    func searchTableViewController(didSelectSearchResultWithSong song: Song) {
        if
            let detail = splitViewController?.viewController(for: .secondary),
            !(detail is SongDetailVC) == true
        {
            if let vc = SongDetailVC.pfw_instantiateFromStoryboard() as? SongDetailVC {
                vc.songsManager = songsManager
                if let detailNav = detail.navigationController {
                    detailNav.setViewControllers([vc], animated: false)
                }
            }
        }
        
        songsManager?.setcurrentSong(song, songsToDisplay: song.collection.songs)
        
        if
            let segmentedControl = segmentedControl,
            let idx = songsManager?.songCollections.firstIndex(of: song.collection)
        {
            segmentedControl.selectedSegmentIndex = idx
            songIndexTableView?.reloadData()
            let ip = indexPathForIndex(song.index)
            
            if let ip = ip {
                songIndexTableView?.scrollToRow(at: ip, at: .middle, animated: false)
            }
        }
        dismiss(animated: true, completion: nil)
    }
}
