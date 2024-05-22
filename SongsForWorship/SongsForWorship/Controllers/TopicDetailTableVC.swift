//
//  TopicDetailTableVC.swift
//  SongsForWorship
//
//  Created by Phil Loden on 5/31/17. Licensed under the MIT license, as follows:
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

class TopicDetailTableVC: UITableViewController, HasFileInfo, SongDetailVCDelegate, AnyIndexVC {
    var fileInfo: FileInfo?

    var topic: Topic!
    var redirects: [Topic] = [Topic]()
    var songsManager: SongsManager!
    var appConfig: AppConfig!
    var settings: Settings!
    
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

            if let song = song {
                songCell?.viewModel = appConfig.songTVCellViewModelClass.init(song)
            }

            if
                let appConfig = appConfig,
                let settings = settings
            {
                songCell?.configureUI(appConfig: appConfig, settings: settings)
            }

            return songCell!
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isRedirectsSection(for: indexPath.section) {
            let redirect = redirects[indexPath.row]

            let viewController = Helper.mainStoryboardForiPhone().instantiateViewController(withIdentifier: "TopicDetailTableVC") as? TopicDetailTableVC
            viewController?.topic = redirect
            viewController?.songsManager = songsManager
            if let viewController = viewController {
                navigationController?.pushViewController(viewController, animated: true)
            }
        } else if let song = self.song(for: indexPath) {
            if
                let detailNav = splitViewController?.viewController(for: .secondary) as? UINavigationController,
                (detailNav.topViewController is SongDetailVC) == false
            {
                if
                    let viewController = SongDetailVC.instantiateFromStoryboard(appConfig: appConfig,
                                                                                    settings: settings,
                                                                                    songsManager: songsManager) as? SongDetailVC
                {
                    detailNav.setViewControllers([viewController], animated: false)
                }
            }

            songsManager.setcurrentSong(song, songsToDisplay: songsToDisplay(for: indexPath))

            if UIDevice.current.userInterfaceIdiom != .pad {
                if
                    let viewController = SongDetailVC.instantiateFromStoryboard(appConfig: appConfig,
                                                                                    settings: settings,
                                                                                    songsManager: songsManager) as? SongDetailVC
                {
                    navigationController?.pushViewController(viewController, animated: true)
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
            for viewController in vcs {
                if
                    let navigationController = viewController as? UINavigationController,
                    let detail = navigationController.topViewController as? SongDetailVC
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

    func song(for indexPath: IndexPath?) -> (Song)? {
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
        let decoder = JSONDecoder()

        guard
            let data = try? Data(contentsOf: url),
            let topic = try? decoder.decode(Topic.self, from: data)
        else
        {
            fatalError("There was an error reading a topic!")
        }

        return topic
    }

}

extension TopicDetailTableVC: HasAppConfig {}

extension TopicDetailTableVC: HasSettings {}
