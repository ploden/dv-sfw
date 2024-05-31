//
//  FavoritesVC.swift
//  SongsForWorship
//
//  Created by Phil Loden on 3/28/21. Licensed under the MIT license, as follows:
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

import Foundation

import UIKit
import SwiftTheme

protocol FavoritesTableViewControllerDelegate: AnyObject {
    func favoritesTableViewController(didSelectFavorite song: Song)
}

class FavoritesVC: UIViewController, UITableViewDelegate, UITableViewDataSource, HasSongsManager {
    override class var storyboardName: String {
        return "Main_iPhone"
    }
    var appConfig: AppConfig!
    var settings: Settings!
    var songsManager: SongsManager! {
        didSet {
            favorites = Self.favoriteSongs(songsManager: songsManager)
        }
    }
    private var favorites: [Song] = [Song]()
    var barTintColorsToRestore: ThemeColorPicker?
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var toolbar: UIToolbar?
    weak var delegate: FavoritesTableViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped(_:)))
        navigationItem.rightBarButtonItem?.theme_tintColor = ThemeColors(
            defaultLight: UIView().tintColor!,
            white: UIColor(named: "NavBarBackground")!,
            night: .white
        ).toHex()

        tableView?.register(UINib(nibName: "SongTVCell", bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: "SongTVCell")

        navigationItem.title = "Bookmarks"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.theme_titleTextAttributes = ThemeStringAttributesPicker(
            [.foregroundColor: UIColor.black],
            [.foregroundColor: UIColor.black],
            [.foregroundColor: UIColor.white]
        )

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

    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }

     func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites.count
    }

     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongTVCell")

        if
            let cell = cell as? SongTVCell,
            indexPath.row < favorites.count
        {
            let song = favorites[indexPath.row]
            cell.viewModel = appConfig.songTVCellViewModelClass.init(song)

            if
                let appConfig = appConfig,
                let settings = settings
            {
                cell.configureUI(appConfig: appConfig, settings: settings)
            }
        }

        return cell!
    }

     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < favorites.count {
            let song = favorites[indexPath.row]
            delegate?.favoritesTableViewController(didSelectFavorite: song)
        }
    }

    // MARK: - IBActions

    @IBAction func doneTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: Helpers

    class func favoriteSongs(songsManager: SongsManager) -> [Song] {
        let favs = FavoritesSyncronizer.favoriteSongNumbers(songsManager: songsManager).compactMap { songsManager.songForNumber($0) }
        return favs
    }
}

extension FavoritesVC: HasAppConfig {}

extension FavoritesVC: HasSettings {}
