//
//  TopicsTableVC.swift
//  SongsForWorship
//
//  Created by Phil Loden on 5/27/17. Licensed under the MIT license, as follows:
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

class TopicsTableVC: UITableViewController, HasFileInfo, HasSongsManager, AnyIndexVC {
    var settings: Settings!
    var appConfig: AppConfig!
    private var topicsSections: [TopicsSection] = [TopicsSection]()
    var songsManager: SongsManager!
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

        if
            let appConfig = appConfig,
            let settings = settings
        {
            cell?.textLabel?.font = Helper.defaultFont(withSize: 16.0, forTextStyle: .title2, appConfig: appConfig, settings: settings)
        }
        
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
                    if
                        let viewController = SongDetailVC.instantiateFromStoryboard(appConfig: appConfig,
                                                                                        settings: settings,
                                                                                        songsManager: songsManager) as? SongDetailVC
                    {
                        detailNav.setViewControllers([viewController], animated: false)
                    }
                }

                songsManager?.setcurrentSong(song, songsToDisplay: [song])

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
        } else if
            topic.redirects?.count == 1,
            let redirect = topic.redirects?[0],
            redirect.count > 0,
            topic.songNumbers.count == 0
        {
            if
                let redirectedLetterTopic = topicsSections.first(where: { $0.section == redirect.prefix(1) }),
                let redirectedTopic = redirectedLetterTopic.topics.first(where: { $0.topic == redirect }),
                let viewController = TopicDetailTableVC.instantiateFromStoryboard(appConfig: appConfig, settings: settings, songsManager: songsManager) as? TopicDetailTableVC
            {
                viewController.topic = redirectedTopic

                viewController.redirects = redirectedTopic.redirects?.compactMap { aRedirect in
                    let aRedirectedLetterTopic = topicsSections.first(where: { $0.section == aRedirect.prefix(1) })
                    return aRedirectedLetterTopic?.topics.first(where: { $0.topic == redirect })
                } ?? [Topic]()

                viewController.songsManager = songsManager
                navigationController?.pushViewController(viewController, animated: true)
            }
        } else {
            let isNotEmpty = topic.subtopics?.count ?? 0 > 0 || topic.songNumbers.count > 0 || topic.redirects?.count ?? 0 > 0

            if isNotEmpty {
                let viewController = TopicDetailTableVC.instantiateFromStoryboard(appConfig: appConfig, settings: settings, songsManager: songsManager) as? TopicDetailTableVC
                viewController?.topic = topic

                viewController?.redirects = topic.redirects?.compactMap { aRedirect in
                    let aRedirectedLetterTopic = topicsSections.first(where: { $0.section == aRedirect.prefix(1) })
                    let match = aRedirectedLetterTopic?.topics.first(where: { $0.topic == aRedirect })
                    return match
                } ?? [Topic]()

                viewController?.songsManager = songsManager
                if let viewController = viewController {
                    navigationController?.pushViewController(viewController, animated: true)
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 34.0
    }

    class func readTopicsSections(fromFileURL url: URL) -> [TopicsSection] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        if
            let data = try? Data.init(contentsOf: url, options: .mappedIfSafe),
            let result = try? decoder.decode([TopicsSection].self, from: data)
        {
            return result
        }

        return [TopicsSection]()
    }
}

extension TopicsTableVC: HasAppConfig {}

extension TopicsTableVC: HasSettings {}
