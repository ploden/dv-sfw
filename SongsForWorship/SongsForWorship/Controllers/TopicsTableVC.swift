//
//  TopicsTableVC.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 5/27/17.
//  Copyright © 2017 Deo Volente, LLC. All rights reserved.
//

import UIKit

class TopicsTableVC: UITableViewController, HasFileURL, HasSongsManager {
    private var lettersTopics: [LetterTopics]?
    var songsManager: SongsManager?
    var fileURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let fileURL = fileURL {
            lettersTopics = TopicsTableVC.readTopics(fromFileURL: fileURL)
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
        var tmpArray = [AnyHashable](repeating: 0, count: lettersTopics?.count ?? 0)
        
        for idx in 0..<(lettersTopics?.count ?? 0) {
            var letter: String? = nil
            if let tmpLetter = lettersTopics?[idx].letter {
                letter = "\(tmpLetter)"
            }
            tmpArray.append(letter?.uppercased(with: NSLocale.current) ?? "")
        }
        
        return tmpArray as? [String]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TopicTVCell", for: indexPath) as? TopicTVCell
        
        cell?.textLabel?.text = {
            if
                let letterTopics = lettersTopics?[indexPath.section]
            {
                return letterTopics.topics[indexPath.row].topic.capitalized(with: NSLocale.current)
            }
            return nil
        }()
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let letterTopics = lettersTopics?[indexPath.section]
        let topic = letterTopics?.topics[indexPath.row]
        
        let isNotEmpty = topic?.subtopics.count ?? 0 > 0 || topic?.songNumbers.count ?? 0 > 0
        
        if isNotEmpty {
            let vc = Helper.mainStoryboard_iPhone().instantiateViewController(withIdentifier: "TopicDetailTableVC") as? TopicDetailTableVC
            vc?.topic = topic
            vc?.songsManager = songsManager
            if let vc = vc {
                navigationController?.pushViewController(vc, animated: true)
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
