//
//  TopicsTableVC.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 5/27/17.
//  Copyright © 2017 Deo Volente, LLC. All rights reserved.
//

import UIKit
import SwiftTheme

class TopicsTableVC: UITableViewController, HasFileInfo, HasSongsManager, HasSettings, AnyIndexVC {
    var settings: Settings?
    private var topicsSections: [TopicsSection] = [TopicsSection]()
    var songsManager: SongsManager?
    var fileInfo: FileInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        
        if
            let fileInfo = fileInfo,
            let path = Bundle.main.path(forResource: fileInfo.0, ofType: fileInfo.1, inDirectory: fileInfo.2)
        {
            let url = URL(fileURLWithPath: path)
            topicsSections = TopicsTableVC.readTopicsSections(fromFileURL: url)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if let theme = ThemeSetting(rawValue: ThemeManager.currentThemeIndex) {
            switch theme {
            case .defaultLight, .night:
                return .lightContent
            case .white:
                return .darkContent
            }
        }
        return .lightContent
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return topicsSections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topicsSections[section].topics.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let letterTopics = topicsSections[section]
                
        return "\(letterTopics.section)".uppercased(with: NSLocale.current)
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        let maxLength = topicsSections.map { $0.section.count }.max()
        
        if maxLength == 1 {
            return topicsSections.compactMap { "\($0.section)".uppercased(with: NSLocale.current) }
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TopicTVCell", for: indexPath) as? TopicTVCell
        
        cell?.textLabel?.text = {
            let letterTopics = topicsSections[indexPath.section]
            let topic = letterTopics.topics[indexPath.row]
            
            let title = topic.topic.capitalized(with: NSLocale.current)
            
            if
                topic.songNumbers.count == 0 && topic.redirects?.count == 1,
                let redirect = topic.redirects?[0]
            {
                
                return "\(title) (See \(redirect.capitalized(with: NSLocale.current)))"
            } else {
                return title
            }
        }()
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let letterTopics = topicsSections[indexPath.section]
        let topic = letterTopics.topics[indexPath.row]
        
        if (topic.subtopics?.count ?? 0 == 0), topic.songNumbers.count == 1 {
            if let song = songsManager?.songForNumber(topic.songNumbers.first) {
                if
                    let detailNav = splitViewController?.viewController(for: .secondary) as? UINavigationController,
                    (detailNav.topViewController is SongDetailVC) == false
                {
                    if let vc = SongDetailVC.pfw_instantiateFromStoryboard() as? SongDetailVC {
                        vc.songsManager = songsManager
                        detailNav.setViewControllers([vc], animated: false)
                    }
                }
                
                songsManager?.setcurrentSong(song, songsToDisplay: [song])
                
                if UIDevice.current.userInterfaceIdiom != .pad {
                    if let vc = SongDetailVC.pfw_instantiateFromStoryboard() as? SongDetailVC {
                        vc.songsManager = songsManager
                        navigationController?.pushViewController(vc, animated: true)
                    }
                }
            }
        } else if
            topic.redirects?.count == 1,
            let redirect = topic.redirects?[0],
            redirect.count > 0,
            topic.songNumbers.count == 0
        {
            if
                let redirectedLetterTopic = topicsSections.first(where: { $0.section == redirect.prefix(1) }),
                let redirectedTopic = redirectedLetterTopic.topics.first(where: { $0.topic == redirect } )
            {
                let vc = Helper.mainStoryboard_iPhone().instantiateViewController(withIdentifier: "TopicDetailTableVC") as? TopicDetailTableVC
                vc?.topic = redirectedTopic
                
                vc?.redirects = redirectedTopic.redirects?.compactMap { aRedirect in
                    let aRedirectedLetterTopic = topicsSections.first(where: { $0.section == aRedirect.prefix(1) })
                    return aRedirectedLetterTopic?.topics.first(where: { $0.topic == redirect })
                } ?? [Topic]()
                
                vc?.songsManager = songsManager
                if let vc = vc {
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        } else {
            let isNotEmpty = topic.subtopics?.count ?? 0 > 0 || topic.songNumbers.count > 0 || topic.redirects?.count ?? 0 > 0
            
            if isNotEmpty {
                let vc = Helper.mainStoryboard_iPhone().instantiateViewController(withIdentifier: "TopicDetailTableVC") as? TopicDetailTableVC
                vc?.topic = topic
                
                vc?.redirects = topic.redirects?.compactMap { aRedirect in
                    let aRedirectedLetterTopic = topicsSections.first(where: { $0.section == aRedirect.prefix(1) })
                    let match = aRedirectedLetterTopic?.topics.first(where: { $0.topic == aRedirect })
                    return match
                } ?? [Topic]()
                
                vc?.songsManager = songsManager
                if let vc = vc {
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 34.0
    }
    
    class func readTopicsSections(fromFileURL url: URL) -> [TopicsSection] {
        do {
            let data = try Data.init(contentsOf: url, options: .mappedIfSafe)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let result = try decoder.decode([TopicsSection].self, from: data)
            return result
        } catch {
            print("There was an error reading topics! \(error)")
        }

        return [TopicsSection]()
    }
}
