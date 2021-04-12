//
//  SearchTableViewController.swift
//  SongsForWorship
//
//  Created by Philip Loden on 3/27/21.
//  Copyright © 2021 Deo Volente, LLC. All rights reserved.
//

import UIKit
import SwiftTheme

protocol SearchTableViewControllerDelegate: class {
    func searchTableViewController(didSelectSearchResultWithSong song: Song)
}

class SearchTableViewController: UITableViewController, HasSongsManager, HasSettings {
    var settings: Settings?
    
    override class var storyboardName: String {
        get {
            return "Main_iPhone"
        }
    }
    var songsManager: SongsManager?
    var isPerformingSearch: Bool = false
    var searchResults: [SearchResult] = [SearchResult]()
    private var isFirstAppearance: Bool = true
    var barTintColorsToRestore: ThemeColorPicker?
    @IBOutlet weak var searchBar: UISearchBar?
    weak var delegate: SearchTableViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView?.register(UINib(nibName: "SearchResultTVCell", bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: "SearchResultTVCell")
        tableView?.rowHeight = UITableView.automaticDimension
        
        self.navigationItem.hidesSearchBarWhenScrolling = false
        searchBar?.showsCancelButton = true
        self.navigationItem.titleView = searchBar
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        barTintColorsToRestore = navigationController?.navigationBar.theme_barTintColor
        navigationController?.navigationBar.theme_barTintColor = ThemeColors(defaultLight: .systemBackground, white: .systemBackground, night: UIColor.systemBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))).toHex()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let barTintColorsToRestore = barTintColorsToRestore {
            navigationController?.navigationBar.theme_barTintColor = barTintColorsToRestore
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstAppearance {
            searchBar?.becomeFirstResponder()
            isFirstAppearance = false
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultTVCell")
        
        if
            let cell = cell as? SearchResultTVCell,
            indexPath.row < searchResults.count
        {
            cell.searchResult = searchResults[indexPath.row]
        }

        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < searchResults.count {
            let searchResult = searchResults[indexPath.row]
                        
            if let song = songsManager?.songForNumber(searchResult.songNumber) {
                if UIDevice.current.userInterfaceIdiom != .pad {
                    let songsToDisplay = searchResults.compactMap { songsManager?.songForNumber($0.songNumber) }
                    songsManager?.setcurrentSong(song, songsToDisplay: songsToDisplay)
                    
                    if let vc = SongDetailVC.pfw_instantiateFromStoryboard() as? SongDetailVC {
                        vc.songsManager = songsManager
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                } else {
                    delegate?.searchTableViewController(didSelectSearchResultWithSong: song)
                }
            }
        }
    }
    
    func doSearch(forTerm term: String?) {
        let allSongs = songsManager?.songCollections.compactMap { $0.songs }.reduce([], { $0 + $1 })
        
        if
            let term = term,
            let allSongs = allSongs
        {
            if isPerformingSearch {
                return
            }
            
            isPerformingSearch = true
            
            Helper.searchResultsForTerm(term, songsArray: allSongs) { [weak self] results in
                let sortedResults = results?.sorted {
                    if
                        let firstSongNumber = $0.songNumber,
                        let secondSongNumber = $1.songNumber
                    {
                        return firstSongNumber.localizedStandardCompare(secondSongNumber) == ComparisonResult.orderedAscending
                        //return firstSongNumber < secondSongNumber
                    }
                    return false
                }
                                    
                OperationQueue.main.addOperation { [weak self] in
                    if let sortedResults = sortedResults {
                        self?.searchResults = sortedResults
                         
                        self?.tableView?.reloadData()
                        
                        self?.isPerformingSearch = false
                        
                        if term != self?.searchBar?.text {
                            self?.doSearch(forTerm: self?.searchBar?.text)
                        }
                    }
                }
            }
        }
    }
    
}

extension SearchTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count > 1 {
            doSearch(forTerm: searchText)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismiss(animated: true, completion: nil)
    }
}
