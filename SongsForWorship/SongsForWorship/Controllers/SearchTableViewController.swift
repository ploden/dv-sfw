//
//  SearchTableViewController.swift
//  SongsForWorship
//
//  Created by Phil Loden on 3/27/21. Licensed under the MIT license, as follows:
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

import UIKit
import SwiftTheme

protocol SearchTableViewControllerDelegate: AnyObject {
    func searchTableViewController(didSelectSearchResultWithSong song: Song)
}

class SearchTableViewController: UITableViewController, HasSongsManager, HasSettings {
    var appConfig: AppConfig!
    var settings: Settings!
    var songsManager: SongsManager!

    override class var storyboardName: String {
        return "Main_iPhone"
    }
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
        navigationController?.navigationBar.theme_barTintColor = ThemeColors(
            defaultLight: .systemBackground,
            white: .systemBackground,
            night: UIColor.systemBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        ).toHex()
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
            let searchResult = searchResults[indexPath.row]
            cell.songNumberLabel?.text = searchResult.songNumber
            cell.titleLabel?.text = searchResult.title

            if
                let appConfig = appConfig,
                let settings = settings
            {
                cell.titleLabel?.font = Helper.defaultFont(withSize: 14.0, forTextStyle: .body, appConfig: appConfig, settings: settings)
            }
        }

        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < searchResults.count {
            let searchResult = searchResults[indexPath.row]

            if let song = songsManager.songForNumber(searchResult.songNumber) {
                if UIDevice.current.userInterfaceIdiom != .pad {
                    let songsToDisplay = searchResults.compactMap { songsManager.songForNumber($0.songNumber) }
                    songsManager.setcurrentSong(song, songsToDisplay: songsToDisplay)

                    if
                        let viewController = SongDetailVC.instantiateFromStoryboard(appConfig: appConfig,
                                                                                        settings: settings,
                                                                                        songsManager: songsManager) as? SongDetailVC
                    {
                        self.navigationController?.pushViewController(viewController, animated: true)
                    }
                } else {
                    delegate?.searchTableViewController(didSelectSearchResultWithSong: song)
                }
            }
        }
    }

    func doSearch(forTerm term: String?) {
        guard isPerformingSearch == false else { return }
        guard let term = term else { return }

        isPerformingSearch = true

        let allSongs: [Song] = songsManager.songCollections.compactMap { $0.songs }.reduce([], { $0 + $1 })

        /// Should we be able to cancel this? 
        _ = Task.init {
            if let results = await Helper.searchResults(forTerm: term, songsArray: allSongs) {
                self.searchResults = results

                self.tableView?.reloadData()

                self.isPerformingSearch = false

                if term != self.searchBar?.text {
                    self.doSearch(forTerm: self.searchBar?.text)
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

extension SearchTableViewController: HasAppConfig {}
