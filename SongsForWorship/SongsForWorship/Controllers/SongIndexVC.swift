//
//  PsalmIndexVC.swift
//  PsalmsForWorship
//
//  Created by PHILIP LODEN on 4/17/10.
//  Copyright 2010 Deo Volente, LLC. All rights reserved.
//

import UIKit

private var kSearchCellID = "SearchResultTVCell"

class SongIndexVC: UIViewController, HasSongsManager, DetailVCDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIViewControllerPreviewingDelegate, UISearchControllerDelegate, UISearchResultsUpdating, PsalmObserver, SongCollectionObserver {
    private var firstTime: Bool = false
    private var isPerformingSearch = false
    private var isObservingcurrentSong = false
    
    var songsManager: SongsManager?
    @IBOutlet weak var songIndexTableView: UITableView?
    @IBOutlet private var copyrightTVCell: UITableViewCell!
    @IBOutlet private var searchBarBackgroundView: UIView!
    private var searchController: UISearchController!
    private var searchResults: [SearchResult]? = [SearchResult]()
    
    private var isSearching: Bool {
        return searchController.isActive && (searchResults != nil)
    }
    private var previewingContext: UIViewControllerPreviewing?
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = ""
        navigationItem.backBarButtonItem?.tintColor = .white

        songIndexTableView?.rowHeight = UITableView.automaticDimension
        songIndexTableView?.estimatedRowHeight = 50.0
        songIndexTableView?.register(UINib(nibName: kSearchCellID, bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: kSearchCellID)
        songIndexTableView?.register(UINib(nibName: "GenericTVCell", bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: "GenericTVCell")
        songIndexTableView?.register(UINib(nibName: "FavoritesHeaderView", bundle: Helper.songsForWorshipBundle()), forHeaderFooterViewReuseIdentifier: "FavoritesHeaderView")
        songIndexTableView?.register(UINib(nibName: "SongTVCell", bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: "SongTVCell")
        
        searchController = UISearchController(searchResultsController: nil)
        
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Search title, verse, tune, or composer"
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        
        searchController.searchBar.searchBarStyle = .prominent
        searchController.searchBar.backgroundColor = UIColor(named: "NavBarBackground")
        searchController.searchBar.barTintColor = .white
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor(named: "NavBarBackground")
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        navigationController?.navigationBar.compactAppearance = navigationBarAppearance
        navigationController?.navigationBar.standardAppearance = navigationBarAppearance
        
        navigationItem.searchController = searchController
        
        if UIDevice.current.userInterfaceIdiom != .pad {
            let navbarLogo = UIImageView(image: UIImage(named: "nav_bar_icon", in: nil, with: .none))
            var frameRect = navbarLogo.frame
            frameRect.origin.x = 30
            navbarLogo.frame = frameRect
            navigationItem.titleView = navbarLogo
        }
        
        if
            let songsManager = songsManager,
            songsManager.songCollections.count > 1
        {
            let segmentedControl = UISegmentedControl(items: songsManager.songCollections.map { $0.displayName } )
            segmentedControl.selectedSegmentIndex = 0
            segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
            segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .selected)
            segmentedControl.tintColor = .white
            segmentedControl.addTarget(self, action: #selector(self.segmentedControlValueChanged(_:)), for: .valueChanged)
            navigationItem.titleView = segmentedControl
        }
        
        let iv = UIImageView(image: UIImage(named: "heart_filled", in: Helper.songsForWorshipBundle(), with: .none))
        iv.frame = CGRect(x: 0.0, y: 0.0, width: 20.0, height: 20.0)
        
        let favoriteBarButtonItem = UIBarButtonItem(image: UIImage(named: "heart_filled", in: Helper.songsForWorshipBundle(), with: .none), style: .plain, target: self, action: #selector(favoriteBarButtonItemTapped(_:)))
        favoriteBarButtonItem.tintColor = .white
        navigationItem.rightBarButtonItem = favoriteBarButtonItem
                
        firstTime = true
        songsManager?.addObserver(forcurrentSong: self)
        songsManager?.addObserver(forSelectedCollection: self)
        isObservingcurrentSong = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(favoritesDidChange(_:)), name: NSNotification.Name.favoritesDidChange, object: nil)
        
        definesPresentationContext = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if UIDevice.current.userInterfaceIdiom != .pad {
            NotificationCenter.default.post(name: NSNotification.Name("stop playing"), object: nil)
        }
        
        let currentSongIndexPath: IndexPath? = {
            var ip: IndexPath?
            
            if
                let songsManager = self.songsManager,
                let currentSong = songsManager.currentSong,
                let songsArray = songsManager.currentCollection?.songs
            {
                if self.isSearching {
                    var idx: Int? = nil
                    if
                        let searchResults = searchResults
                    {
                        let songsArray: [Song] = searchResults.compactMap { $0.song(songsArray) }
                        idx = songsArray.firstIndex(of: currentSong)
                    }
                    ip = IndexPath(row: idx ?? 0, section: 0)
                } else if (songsManager.songsToDisplay == IndexVC.favoriteSongs(songsArray)) {
                    var idx: Int? = nil
                    idx = IndexVC.favoriteSongs(songsArray).firstIndex(of: currentSong) ?? NSNotFound
                    
                    if idx != NSNotFound {
                        return IndexPath(row: idx ?? 0, section: 0)
                    }
                } else {
                    ip = self.indexPathForIndex(currentSong.index)
                }
            }
            
            return ip
        }()
        
        let selectedRowIndexPath = songIndexTableView?.indexPathForSelectedRow
        
        if
            let currentSongIndexPath = currentSongIndexPath,
            selectedRowIndexPath != nil && currentSongIndexPath != selectedRowIndexPath
        {
            songIndexTableView?.selectRow(at: currentSongIndexPath, animated: false, scrollPosition: .middle)
            if !isSearching {
                songIndexTableView?.scrollToNearestSelectedRow(at: .middle, animated: false)
            }
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
        
        if isForceTouchAvailable() {
            previewingContext = registerForPreviewing(with: self, sourceView: view)
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
        if isSearching {
            return 1
        } else if let count = songsManager?.currentCollection?.sections.count {
            return count + 1
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index + 1
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if isFavoritesSection(section) {
            return " "
        }
        return nil
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if isSearching {
            return nil
        } else {
            if let sections = songsManager?.currentCollection?.sections {
                return sections.map { $0.title }
            } else {
                return nil
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            return searchResults?.count ?? 0
        } else if isFavoritesSection(section) {
            let favoritesCount = FavoritesSyncronizer.favorites().count
            return max(1, favoritesCount)
        } else if
            let sections = songsManager?.currentCollection?.sections,
            section - 1 >= 0,
            section - 1 < sections.count
        {
            let collectionSection = sections[section - 1]
            return collectionSection.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if isSearching == false && isFavoritesSection(section) {
            return 44.0
        }
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let classStr = "FavoritesHeaderView"
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: classStr)
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if isSearching == false && isFavoritesSection(section) {
            return 10.0
        }
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if firstTime {
            //tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .top, animated: false)
            firstTime = false
        }
        
        if isSearching {
            let cell = tableView.dequeueReusableCell(withIdentifier: kSearchCellID) as? SearchResultTVCell
            if
                let searchResults = searchResults,
                indexPath.row < searchResults.count
            {
                cell?.searchResult = searchResults[indexPath.row]
            }
            return cell!
        } else if tableView == songIndexTableView {
            if isCopyrightTVCell(indexPath) {
                let tvc = songIndexTableView?.dequeueReusableCell(withIdentifier: "GenericTVCell") as? GenericTVCell
                tvc?.textLabel?.text = Helper.copyrightString(nil)
                tvc?.textLabel?.textAlignment = .center
                tvc?.textLabel?.font = Helper.defaultFont(withSize: 9.0, forTextStyle: .body)
                tvc?.textLabel?.numberOfLines = 2
                tvc?.textLabel?.textColor = UIColor(red: 80.0 / 256.0, green: 80.0 / 256.0, blue: 80.0 / 256.0, alpha: 1.0)
                tvc?.selectionStyle = .none
                return tvc!
            } else if isFavoritesSection(indexPath.section) && FavoritesSyncronizer.favorites().count == 0 {
                // show favs will appear here cell
                let generic = tableView.dequeueReusableCell(withIdentifier: "GenericTVCell") as? GenericTVCell
                generic?.textLabel?.textColor = UIColor.lightGray
                generic?.textLabel?.font = generic?.textLabel?.font.withSize(12.0)
                generic?.textLabel?.text = "Favorited songs will appear here."
                generic?.selectionStyle = .none
                return generic!
            } else {
                let song = self.songForIndexPath(indexPath)
                
                let songCell = tableView.dequeueReusableCell(withIdentifier: "SongTVCell") as? SongTVCell
                songCell?.configureWithPsalm(song, isFavorite: isFavoritesSection(indexPath.section))
                return songCell!
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if isFavoritesSection(indexPath.section) && FavoritesSyncronizer.favorites().count == 0 {
            return nil
        } else {
            return indexPath
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isCopyrightTVCell(indexPath) == false {
            let song = self.songForIndexPath(indexPath)
            
            let toDisplay: [Song] = {
                if self.isSearching == false && self.isFavoritesSection(indexPath.section) {
                    return IndexVC.favoriteSongs(songsManager?.currentCollection?.songs)
                } else {
                    return self.songsToDisplay() ?? [Song]()
                }
            }()
            
            songsManager?.setcurrentSong(song, songsToDisplay: toDisplay)
            
            if UIDevice.current.userInterfaceIdiom != .pad {
                let vc = TabBarController.pfw_instantiateFromStoryboard() as? TabBarController
                vc?.songsManager = songsManager
                
                if let vc = vc {
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    // MARK: - helper methods
    
    func isFavoritesSection(_ section: Int) -> Bool {
        if isSearching == true {
            return false
        } else {
            return section == 0
        }
    }
    
    func isCopyrightTVCell(_ indexPath: IndexPath?) -> Bool {
        if indexPath?.section == 16 && indexPath?.row == 25 {
            return true
        }
        
        return false
    }
    
    func songsToDisplay() -> [Song]? {
        if isSearching {
            if
                let searchResults = searchResults,
                let songsArray = songsManager?.currentCollection?.songs
            {
                var songs: [Song] = [Song]()
                
                for result in searchResults {
                    let resultPsalm = result.song(songsArray)
                    songs.append(resultPsalm)
                }
                
                return songs
            }
        } else {
            return songsManager?.currentCollection?.songs
        }
        return nil
    }
    
    func indexForIndexPath(_ indexPath: IndexPath) -> Int {
        var count = 0
        if let songIndexTableView = songIndexTableView {
            for i in 1..<indexPath.section {
                // start at 1 because of favs
                count += songIndexTableView.numberOfRows(inSection: i)
            }
        }
        return count + indexPath.row
    }
    
    func indexPathForIndex(_ index: Int) -> IndexPath? {
        if let songIndexTableView = songIndexTableView {
            var count = 0
            var sectionIdx = 0
            
            // Start at one to skip Favorites.
            for idx in 1..<songIndexTableView.numberOfSections {
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
            let songsArray = songsManager?.currentCollection?.songs,
            let indexPath = indexPath
        {
            if isSearching {
                let searchResult = searchResults?[indexPath.row]
                song = searchResult?.song(songsArray)
            } else {
                if isFavoritesSection(indexPath.section) {
                    song = IndexVC.favoritePsalmForIndexPath(indexPath, allSongs: songsArray)
                } else {
                    song = songsArray[indexForIndexPath(indexPath)]
                }
            }
        }
        
        return song
    }
    
    func doSearch(forTerm term: String?) {
        if
            let term = term,
            let songsArray = songsManager?.currentCollection?.songs
        {
            if isPerformingSearch {
                return
            }
            
            isPerformingSearch = true
            
            Helper.searchResultsForTerm(term, songsArray: songsArray) { [weak self] results in
                if let results = results {
                    self?.searchResults = results
                    
                    var songs = [Song]()
                    
                    if
                        let searchResults = self?.searchResults,
                        let songsArray = self?.songsManager?.currentCollection?.songs
                    {
                        for result in searchResults {
                            let resultPsalm = result.song(songsArray)
                            songs.append(resultPsalm)
                        }
                    }
                    
                    self?.songIndexTableView?.reloadData()
                    
                    self?.isPerformingSearch = false
                    
                    if !(term == self?.searchController.searchBar.text) {
                        self?.doSearch(forTerm: self?.searchController.searchBar.text)
                    }
                }
            }
        }
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
                    if self.isSearching {
                        var idx: Int? = nil
                        
                        if
                            let songsArray = songsManager.currentCollection?.songs,
                            let searchResults = searchResults
                        {
                            let songsArray: [Song] = searchResults.compactMap { $0.song(songsArray) }
                            idx = songsArray.firstIndex(of: current)
                            ip = IndexPath(row: idx ?? 0, section: 0)
                        }
                    } else if (songsManager.songsToDisplay == IndexVC.favoriteSongs(songsManager.currentCollection?.songs)) {
                        var idx: Int? = nil
                        idx = IndexVC.favoriteSongs(songsManager.currentCollection?.songs).firstIndex(of: current) ?? NSNotFound
                        
                        if idx != NSNotFound {
                            return IndexPath(row: idx ?? 0, section: 0)
                        }
                    } else {
                        ip = self.indexPathForIndex(current.index)
                    }
                }
                
                return ip
            }()
            
            let selectedRowIndexPath = songIndexTableView?.indexPathForSelectedRow
            
            if
                UIDevice.current.userInterfaceIdiom == .pad,
                let selectedRowIndexPath = selectedRowIndexPath,
                currentSongIndexPath != selectedRowIndexPath
            {
                if isFavoritesSection(currentSongIndexPath?.section ?? 0) {
                    songIndexTableView?.selectRow(at: currentSongIndexPath, animated: true, scrollPosition: .none)
                } else {
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
    }
    
    deinit {
        if isObservingcurrentSong {
            songsManager?.removeObserver(forcurrentSong: self)
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func songTVCellFavoriteButtonTapped(_ tvc: SongTVCell?) {
        if
            let tvc = tvc,
            let ip = songIndexTableView?.indexPath(for: tvc),
            let aSong = songForIndexPath(ip)
        {
            FavoritesSyncronizer.removeFromFavorites(aSong)
        }
    }
    
    // MARK: - UISearchControllerDelegate
    func updateSearchResults(for searchController: UISearchController) {
        // do the search for nonempty string
        if (searchController.searchBar.text?.count ?? 0) != 0 {
            doSearch(forTerm: searchController.searchBar.text)
        } else {
            searchResults = nil
            songIndexTableView?.reloadData()
        }
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.searchBarStyle = .prominent
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        searchController.searchBar.searchBarStyle = .minimal
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        songIndexTableView?.reloadData()
    }
    
    @objc func keyboardWillShow(_ notification: Notification?) {
        let userInfo = notification?.userInfo
        if let value = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let endFrame = value.cgRectValue
            let insets = UIEdgeInsets(top: 0, left: 0, bottom: endFrame.height, right: 0)
            songIndexTableView?.contentInset = insets
            songIndexTableView?.scrollIndicatorInsets = insets
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification?) {
        songIndexTableView?.contentInset = .zero
        songIndexTableView?.scrollIndicatorInsets = .zero
    }
    
    @objc func favoritesDidChange(_ notification: Notification?) {
        let set = NSIndexSet(index: 0)
        songIndexTableView?.reloadSections(set as IndexSet, with: .none)
    }
    
    // MARK: -
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        let newPoint = view.convert(location, to: songIndexTableView)
        let index = songIndexTableView?.indexPathForRow(at: newPoint)
        if index == nil || (index?.section == 16 && index?.row == 27) {
            return nil
        }
        
        var sourceRect: CGRect? = nil
        if let index = index {
            sourceRect = songIndexTableView?.rectForRow(at: index)
        }
        previewingContext.sourceRect = view.convert(sourceRect ?? CGRect.zero, from: songIndexTableView)
        
        if
            let index = index,
            let song = SongsManager.songAtIndex(self.indexForIndexPath(index), allSongs: songsToDisplay())
        {
            return SongPreviewViewController(withPsalm: song)
        }
        
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if !(viewControllerToCommit is SongPreviewViewController) {
            return
        }
        
        let previewController = viewControllerToCommit as? SongPreviewViewController
        let song = previewController?.song
        
        if let songsManager = songsManager {
            songsManager.setcurrentSong(song, songsToDisplay: songsManager.songsToDisplay)
        }
        
        let vc = TabBarController.pfw_instantiateFromStoryboard() as? TabBarController
        vc?.songsManager = songsManager
        if let vc = vc {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if isForceTouchAvailable() {
            if previewingContext == nil {
                previewingContext = registerForPreviewing(with: self, sourceView: view)
            }
        } else {
            if let previewingContext = previewingContext {
                unregisterForPreviewing(withContext: previewingContext)
            }
        }
    }
    
    func startSearching() {
        loadViewIfNeeded()
        
        // not working without dispatch
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
            self.searchController.isActive = true
            self.songIndexTableView?.scrollRectToVisible(self.searchController.searchBar.frame, animated: true)
        })
    }
    
    // MARK: - DetailVCDelegate
    func songsToDisplayForDetailVC(_ detailVC: DetailVC?) -> [Song]? {
        return songsToDisplay()
    }
    
    func isSearchingForDetailVC(_ detailVC: DetailVC?) -> Bool {
        return isSearching
    }
    
    // MARK: - IBActions
    @IBAction func favoriteBarButtonItemTapped(_ sender: Any) {
        songIndexTableView?.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: Any) {
        if
            let segmentedControl = sender as? UISegmentedControl,
            let collectionName = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex)
        {
            songsManager?.selectSongCollection(withName: collectionName)
        }
    }
    
    func selectedCollectionDidChange(_ notification: Notification) {
        songIndexTableView?.reloadData()
    }
}
