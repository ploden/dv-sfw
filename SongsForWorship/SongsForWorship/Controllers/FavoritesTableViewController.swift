//
//  FavoritesTableViewController.swift
//  SongsForWorship
//
//  Created by Philip Loden on 3/28/21.
//  Copyright © 2021 Deo Volente, LLC. All rights reserved.
//

import Foundation

import UIKit

protocol FavoritesTableViewControllerDelegate: class {
    func favoritesTableViewController(didSelectFavorite song: Song)
}

class FavoritesVC: UIViewController, UITableViewDelegate, UITableViewDataSource, HasSongsManager {
    override class var storyboardName: String {
        get {
            return "Main_iPhone"
        }
    }
    var songsManager: SongsManager? {
        didSet {
            if let songsManager = songsManager {
                favorites = IndexVC.favoriteSongs(songsManager: songsManager)
            } else {
                favorites = [Song]()
            }
        }
    }
    private var favorites: [Song] = [Song]()
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var toolbar: UIToolbar?
    weak var delegate: FavoritesTableViewControllerDelegate?
        
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped(_:)))
        navigationItem.title = "Bookmarks"
        
        tableView?.register(UINib(nibName: "SongTVCell", bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: "SongTVCell")
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.backgroundColor = nil
        navigationController?.navigationBar.standardAppearance = navBarAppearance
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
            cell.configureWithPsalm(song, isFavorite: false)
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
}
