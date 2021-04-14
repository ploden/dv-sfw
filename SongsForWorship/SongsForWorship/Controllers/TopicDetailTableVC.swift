//  Converted to Swift 5.1 by Swiftify v5.1.30744 - https://objectivec2swift.com/
//
//  TopicDetailTableVC.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 5/31/17.
//  Copyright © 2017 Deo Volente, LLC. All rights reserved.
//

import UIKit

class TopicDetailTableVC: UITableViewController, HasFileInfo, SongDetailVCDelegate {
    var fileInfo: FileInfo?
    
    var topic: Topic!
    var redirects: [Topic] = [Topic]()
    var songsManager: SongsManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        if
            let fileInfo = fileInfo,
            let path = Bundle.main.path(forResource: fileInfo.0, ofType: fileInfo.1, inDirectory: fileInfo.2)
        {
            let url = URL(fileURLWithPath: path)
            topic = TopicDetailTableVC.readTopic(fromFileURL: url)
        }
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50.0
        tableView.register(TopicTVCell.self, forCellReuseIdentifier: "TopicTVCell")
        tableView.register(UINib(nibName: "SongTVCell", bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: "SongTVCell")

        navigationItem.title = topic.topic.capitalized(with: NSLocale.current)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let detail = self.detailVC() {
            detail.delegate = self
        }
        
        navigationController?.setToolbarHidden(true, animated: true)        
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        let hasRedirects = redirects.count > 0
        
        if let subtopics = topic.subtopics, subtopics.count > 0 {
            return subtopics.count + (hasRedirects ? 1 : 0)
        } else {
            return 1 + (hasRedirects ? 1 : 0)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isRedirectsSection(for: section) {
            return redirects.count
        } else if topic.subtopics?.count ?? 0 > 0 {
            let subtopic = topic.subtopics?[section]
            return subtopic?.songNumbers.count ?? 0
        } else {
            return topic.songNumbers.count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isRedirectsSection(for: section) {
            return "See also"
        } else if section < topic.subtopics?.count ?? 0 {
            let subtopic = topic.subtopics?[section]
            return subtopic?.topic.capitalized(with: NSLocale.current)
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isRedirectsSection(for: indexPath.section) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TopicTVCell", for: indexPath) as? TopicTVCell

            cell?.textLabel?.text = redirects[indexPath.row].topic.capitalized(with: NSLocale.current)
            
            return cell!
        } else {
            let songCell = tableView.dequeueReusableCell(withIdentifier: "SongTVCell") as? SongTVCell
            
            let song = self.song(for: indexPath)
            songCell?.configureWithPsalm(song, isFavorite: false)
            
            return songCell!
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isRedirectsSection(for: indexPath.section) {
            let redirect = redirects[indexPath.row]
            
            let vc = Helper.mainStoryboard_iPhone().instantiateViewController(withIdentifier: "TopicDetailTableVC") as? TopicDetailTableVC
            vc?.topic = redirect
            vc?.songsManager = songsManager
            if let vc = vc {
                navigationController?.pushViewController(vc, animated: true)
            }
        } else if let song = self.song(for: indexPath) {
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
            
            songsManager.setcurrentSong(song, songsToDisplay: songsToDisplay(for: indexPath))
            
            if UIDevice.current.userInterfaceIdiom != .pad {
                if let vc = SongDetailVC.pfw_instantiateFromStoryboard() as? SongDetailVC {
                    vc.songsManager = songsManager
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    func isRedirectsSection(for section: Int) -> Bool {
        if
            let topicRedirects = topic.redirects, topicRedirects.count == 0
        {
            return false
        } else if
            let topicSubtopics = topic.subtopics, topicSubtopics.count > 0
        {
            if section == topicSubtopics.count {
                return true
            }
        } else if section == 1 {
            return true
        }
        return false
    }
    
    func detailVC() -> SongDetailVC? {
        if let vcs = splitViewController?.viewControllers {
            for vc in vcs {
                if
                    let nc = vc as? UINavigationController,
                    let detail = nc.topViewController as? SongDetailVC
                {
                    return detail
                }
            }
        }
        return nil
    }
    
    func songsToDisplay(for indexPath: IndexPath?) -> [Song] {
        let songNumbers: [String] = {
            if
                let subtopics = topic.subtopics,
                let indexPath = indexPath
            {
                if subtopics.count == 0 {
                    return topic.songNumbers
                } else {
                    if indexPath.section < subtopics.count {
                        return subtopics[indexPath.section].songNumbers
                    }
                }
            }
            return topic.songNumbers            
        }()
        
        return songNumbers.compactMap { songsManager.songForNumber($0) }
    }
    
    func song(for indexPath: IndexPath?) -> Song? {
        let songNumber: String = {
            if self.topic.subtopics == nil || self.topic.subtopics?.count == 0 {
                if (indexPath?.row ?? 0) < self.topic.songNumbers.count {
                    return self.topic.songNumbers[indexPath?.row ?? 0]
                }
            } else if let subtopics = self.topic.subtopics {
                if (indexPath?.section ?? 0) < subtopics.count && (indexPath?.row ?? 0) < subtopics[indexPath?.section ?? 0].songNumbers.count {
                    return subtopics[indexPath?.section ?? 0].songNumbers[indexPath?.row ?? 0]
                }
            }
            return ""
        }()
        
        let song = songsManager.songForNumber(songNumber)
        return song
    }
    
    // MARK: - DetailVCDelegate
    func songsToDisplayForDetailVC(_ detailVC: SongDetailVC?) -> [Song]? {
        let selected = tableView.indexPathForSelectedRow
        
        if selected != nil {
            return songsToDisplay(for: selected)
        } else {
            return songsToDisplay(for: IndexPath(row: 0, section: 0))
        }
    }
    
    func isSearchingForDetailVC(_ detailVC: SongDetailVC?) -> Bool {
        return false
    }
    
    class func readTopic(fromFileURL url: URL) -> Topic {
        var result: Topic?
        
        do {
            let data = try Data.init(contentsOf: url, options: .mappedIfSafe)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            result = try decoder.decode(Topic.self, from: data)
        } catch {
            print("There was an error reading app config! \(error)")
        }
        
        return result!
    }
}
