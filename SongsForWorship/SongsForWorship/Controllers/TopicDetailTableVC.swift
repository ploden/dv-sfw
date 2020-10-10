//  Converted to Swift 5.1 by Swiftify v5.1.30744 - https://objectivec2swift.com/
//
//  TopicDetailTableVC.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 5/31/17.
//  Copyright © 2017 Deo Volente, LLC. All rights reserved.
//

import UIKit

class TopicDetailTableVC: UITableViewController, DetailVCDelegate {
    var topic: Topic!
    var songsManager: SongsManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "SongTVCell", bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: "SongTVCell")
        
        navigationItem.title = topic.topic.capitalized(with: NSLocale.current)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let detail = self.detailVC() {
            detail.delegate = self
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return max(1, topic.subtopics.count)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if topic.subtopics.count > 0 {
            let subtopic = topic.subtopics[section]
            return subtopic.songNumbers.count
        } else {
            return topic.songNumbers.count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < topic.subtopics.count {
            let subtopic = topic.subtopics[section]
            return subtopic.topic.capitalized(with: NSLocale.current)
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let songCell = tableView.dequeueReusableCell(withIdentifier: "SongTVCell") as? SongTVCell
        
        let song = self.song(for: indexPath)
        songCell?.configureWithPsalm(song, isFavorite: false)
        
        return songCell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let song = self.song(for: indexPath) {
            songsManager.setcurrentSong(song, songsToDisplay: songsToDisplay(for: indexPath))
            
            if UIDevice.current.userInterfaceIdiom != .pad {
                let vc = TabBarController.pfw_instantiateFromStoryboard() as? TabBarController
                vc?.songsManager = songsManager
                
                if let vc = vc {
                    navigationController?.pushViewController(vc, animated: true)
                }
            } else {
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54.0
    }
    
    // MARK: - Helpers
    func detailVC() -> DetailVC? {
        if let vcs = splitViewController?.viewControllers {
            for vc in vcs {
                if
                    let nc = vc as? UINavigationController,
                    let detail = nc.topViewController as? DetailVC
                {
                    return detail
                }
            }
        }
        return nil
    }
    
    func songsToDisplay(for indexPath: IndexPath?) -> [Song] {
        var songs = [Song]()
        
        let songNumbers: [String] = {
            if self.topic.subtopics.count == 0 {
                return self.topic.songNumbers
            } else {
                if (indexPath?.section ?? 0) < self.topic.subtopics.count {
                    return self.topic.subtopics[indexPath?.section ?? 0].songNumbers
                }
            }
            return []
        }()
        
        for songNumber in songNumbers {
            if let song = songsManager.currentCollection?.songForNumber(songNumber) {
                songs.append(song)
            }
        }
        
        return songs
    }
    
    func song(for indexPath: IndexPath?) -> Song? {
        let songNumber: String = {
            if self.topic.subtopics.count == 0 {
                if (indexPath?.row ?? 0) < self.topic.songNumbers.count {
                    return self.topic.songNumbers[indexPath?.row ?? 0]
                }
            } else {
                if (indexPath?.section ?? 0) < self.topic.subtopics.count && (indexPath?.row ?? 0) < self.topic.subtopics[indexPath?.section ?? 0].songNumbers.count {
                    return self.topic.subtopics[indexPath?.section ?? 0].songNumbers[indexPath?.row ?? 0]
                }
            }
            return ""
        }()
        
        let song = songsManager.songForNumber(songNumber)
        return song
    }
    
    // MARK: - DetailVCDelegate
    func songsToDisplayForDetailVC(_ detailVC: DetailVC?) -> [Song]? {
        let selected = tableView.indexPathForSelectedRow
        
        if selected != nil {
            return songsToDisplay(for: selected)
        } else {
            return songsToDisplay(for: IndexPath(row: 0, section: 0))
        }
    }
    
    func isSearchingForDetailVC(_ detailVC: DetailVC?) -> Bool {
        return false
    }
}
