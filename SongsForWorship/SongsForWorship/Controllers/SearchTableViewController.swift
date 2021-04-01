//
//  SearchTableViewController.swift
//  SongsForWorship
//
//  Created by Philip Loden on 3/27/21.
//  Copyright © 2021 Deo Volente, LLC. All rights reserved.
//

import UIKit

class SearchTableViewController: UITableViewController, HasSongsManager {
    override class var storyboardName: String {
        get {
            return "Main_iPhone"
        }
    }
    var songsManager: SongsManager?
    var isPerformingSearch: Bool = false
    var searchResults: [SearchResult] = [SearchResult]()
    private var isFirstAppearance: Bool = true
    @IBOutlet weak var searchBar: UISearchBar?
        
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView?.register(UINib(nibName: "SearchResultTVCell", bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: "SearchResultTVCell")

        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.navigationItem.titleView = searchBar
        
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = nil        
        navigationController?.navigationBar.standardAppearance = appearance
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
            
            let song = songsManager?.songForNumber(searchResult.songNumber)
                        
            if let song = song {
                let songsToDisplay = searchResults.compactMap { songsManager?.songForNumber($0.songNumber) }

                songsManager?.setcurrentSong(song, songsToDisplay: songsToDisplay)
                
                if let vc = MetreVC_iPhone.pfw_instantiateFromStoryboard() as? MetreVC_iPhone {
                    vc.songsManager = songsManager
                    self.navigationController?.pushViewController(vc, animated: true)
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