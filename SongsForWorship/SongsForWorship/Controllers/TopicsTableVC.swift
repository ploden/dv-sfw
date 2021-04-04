//
//  TopicsTableVC.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 5/27/17.
//  Copyright © 2017 Deo Volente, LLC. All rights reserved.
//

import UIKit

class TopicsTableVC: UITableViewController, HasFileInfo, HasSongsManager, HasSettings {
    var settings: Settings?
    
    private var lettersTopics: [LetterTopics]?
    var songsManager: SongsManager?
    var fileInfo: FileInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let app = UIApplication.shared.delegate as? PsalterAppDelegate {
            settings = app.settings
        }
        
        if
            let fileInfo = fileInfo,
            let path = Bundle.main.path(forResource: fileInfo.0, ofType: fileInfo.1, inDirectory: fileInfo.2)
        {
            let url = URL(fileURLWithPath: path)
            lettersTopics = TopicsTableVC.readTopics(fromFileURL: url)
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
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return lettersTopics?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lettersTopics?[section].topics.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let letterTopics = lettersTopics?[section]
        if let letter = letterTopics?.letter {
            return "\(letter)".uppercased(with: NSLocale.current)
        }
        return nil
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return lettersTopics?.compactMap { "\($0.letter)".uppercased(with: NSLocale.current) }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TopicTVCell", for: indexPath) as? TopicTVCell
        
        cell?.textLabel?.text = {
            if let letterTopics = lettersTopics?[indexPath.section] {
                let topic = letterTopics.topics[indexPath.row]
                
                let title = topic.topic.capitalized(with: NSLocale.current)
                
                if topic.songNumbers.count == 0 && topic.redirects.count == 1 {
                    return "\(title) (See \(topic.redirects[0].capitalized(with: NSLocale.current)))"
                } else {
                    return title
                }
            }
            return nil
        }()
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let letterTopics = lettersTopics?[indexPath.section]
        let topic = letterTopics?.topics[indexPath.row]
        
        if let topic = topic {
            if topic.subtopics.count == 0 && topic.songNumbers.count == 1 {
                if let song = songsManager?.songForNumber(topic.songNumbers.first) {
                    songsManager?.setcurrentSong(song, songsToDisplay: [song])
                    
                    if UIDevice.current.userInterfaceIdiom != .pad {
                        if let vc = MetreVC_iPhone.pfw_instantiateFromStoryboard() as? MetreVC_iPhone {
                            vc.settings = settings
                            vc.songsManager = songsManager
                            navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                }
            } else if topic.redirects.count == 1 && topic.songNumbers.count == 0 {
                let redirect = topic.redirects[0]
                
                if
                    let redirectedLetterTopic = lettersTopics?.first(where: { $0.letter == redirect.first }),
                    let redirectedTopic = redirectedLetterTopic.topics.first(where: { $0.topic == redirect } )
                {
                    let vc = Helper.mainStoryboard_iPhone().instantiateViewController(withIdentifier: "TopicDetailTableVC") as? TopicDetailTableVC
                    vc?.topic = redirectedTopic
                    
                    vc?.redirects = redirectedTopic.redirects.compactMap { aRedirect in
                        let aRedirectedLetterTopic = lettersTopics?.first(where: { $0.letter == aRedirect.first })
                        return aRedirectedLetterTopic?.topics.first(where: { $0.topic == redirect })
                    }
                    
                    vc?.songsManager = songsManager
                    if let vc = vc {
                        navigationController?.pushViewController(vc, animated: true)
                    }
                }
            } else {
                let isNotEmpty = topic.subtopics.count > 0 || topic.songNumbers.count > 0 || topic.redirects.count > 0
                
                if isNotEmpty {
                    let vc = Helper.mainStoryboard_iPhone().instantiateViewController(withIdentifier: "TopicDetailTableVC") as? TopicDetailTableVC
                    vc?.topic = topic
                    
                    vc?.redirects = topic.redirects.compactMap { aRedirect in
                        let aRedirectedLetterTopic = lettersTopics?.first(where: { $0.letter == aRedirect.first })
                        let match = aRedirectedLetterTopic?.topics.first(where: { $0.topic == aRedirect })
                        return match
                    }
                    
                    vc?.songsManager = songsManager
                    if let vc = vc {
                        navigationController?.pushViewController(vc, animated: true)
                    }
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 34.0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 34.0
    }
    
    class func readTopics(fromFileURL url: URL) -> [LetterTopics] {
        var _: Error? = nil
        var jsonString: String? = nil
        do {
            jsonString = try String(contentsOf: url, encoding: .utf8)
        } catch {
        }
        
        let jsonData = jsonString?.data(using: .utf8)
        var _: Error? = nil
        var lettersTopicsDicts: [AnyHashable]? = nil
        do {
            if let jsonData = jsonData {
                lettersTopicsDicts = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [AnyHashable]
            }
        } catch {
        }
        
        var letterTopicsArray: [LetterTopics]? = []
        
        if let lettersTopicsDicts = lettersTopicsDicts {
            for dict in lettersTopicsDicts {
                guard let dict = dict as? [AnyHashable : Any] else {
                    continue
                }
                
                if
                    let letter = dict["letter"] as? String,
                    let topicDicts = dict["topics"] as? [AnyHashable]
                {
                    var topicsArray: [Topic]? = []
                    
                    for topicDict in topicDicts {
                        guard let topicDict = topicDict as? [AnyHashable : Any] else {
                            continue
                        }
                        if let topic = Topic(dict: topicDict) {
                            topicsArray?.append(topic)
                        }
                    }

                    if
                        let letterCharacter = letter.first,
                        let topicsArray = topicsArray, 
                        let letterTopics = LetterTopics(letter: letterCharacter, topics: topicsArray)
                    {
                        letterTopicsArray?.append(letterTopics)
                    }
                }
            }
        }
        
        return letterTopicsArray ?? []
    }
}
