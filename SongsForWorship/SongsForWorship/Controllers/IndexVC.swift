//
//  IndexVC.swift
//  SongsForWorship
//
//  Created by Phil Loden on 12/28/10. Licensed under the MIT license, as follows:
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

public extension Bundle {
    var appName: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    }
    var version: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}

import MessageUI
import SwiftTheme

class IndexVC: UIViewController, HasSongsManager, AnyIndexVC, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate {
    var settings: Settings!
    var appConfig: AppConfig!
    var songsManager: SongsManager!
    var sections: [IndexSection]!

    enum FeedbackSectionRow: Int {
        case settings = 0, feedback, count
    }

    @IBOutlet private var indexTableView: UITableView?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = ""
        configureNavBar()

        Settings.addObserver(forTheme: self)

        let nibName = String(describing: GenericTVCell.self)
        indexTableView?.register(UINib(nibName: nibName, bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: nibName)
        indexTableView?.rowHeight = UITableView.automaticDimension
        indexTableView?.estimatedRowHeight = 50.0
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        indexTableView?.reloadData()

        navigationController?.setToolbarHidden(true, animated: true)

        if UIDevice.current.userInterfaceIdiom != .pad {
            NotificationCenter.default.post(name: NSNotification.Name("stop playing"), object: nil)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let selection = indexTableView?.indexPathForSelectedRow {
            indexTableView?.deselectRow(at: selection, animated: true)
        }
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        (UIApplication.shared.delegate as? SFWAppDelegate)?.changeThemeAsNeeded()
    }

    // MARK: - Helper methods

    func configureNavBar() {
        guard
            let settings = Settings(fromUserDefaults: .standard),
            let image = UIImage(named: "nav_bar_icon", in: nil, with: .none)
        else
        {
            return
        }

        switch settings.theme {
        case .defaultLight:
            let navbarLogo = UIImageView(image: image)
            navigationItem.titleView = navbarLogo
        case .night:
            let templateImage = image.withRenderingMode(.alwaysTemplate)
            let navbarLogo = UIImageView(image: templateImage)
            navbarLogo.tintColor = .white
            navigationItem.titleView = navbarLogo
        case .white:
            let templateImage = image.withRenderingMode(.alwaysTemplate)
            let navbarLogo = UIImageView(image: templateImage)
            navbarLogo.tintColor = UIColor(named: "NavBarBackground")!
            navigationItem.titleView = navbarLogo
        }
    }

    private func createEmailUrl(to: String, subject: String, body: String) -> URL? {
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

        let gmailUrl = URL(string: "googlegmail://co?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let outlookUrl = URL(string: "ms-outlook://compose?to=\(to)&subject=\(subjectEncoded)")
        let yahooMail = URL(string: "ymail://mail/compose?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let sparkUrl = URL(string: "readdle-spark://compose?recipient=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")

        if let gmailUrl = gmailUrl, UIApplication.shared.canOpenURL(gmailUrl) {
            return gmailUrl
        } else if let outlookUrl = outlookUrl, UIApplication.shared.canOpenURL(outlookUrl) {
            return outlookUrl
        } else if let yahooMail = yahooMail, UIApplication.shared.canOpenURL(yahooMail) {
            return yahooMail
        } else if let sparkUrl = sparkUrl, UIApplication.shared.canOpenURL(sparkUrl) {
            return sparkUrl
        } else {
            return nil
        }
    }

    func detailVC() -> SongDetailVC? {
        if let vcs = splitViewController?.viewControllers {
            for vc in vcs {
                if
                    let navController = vc as? UINavigationController,
                    let detail = navController.topViewController as? SongDetailVC
                {
                    return detail
                }
            }
        }
        return nil
    }

    func sendFeedback() {
        if let recipient = appConfig?.sendFeedbackEmailAddress {
            let subject: String = {
                let appName = Bundle.main.appName
                let version = Bundle.main.version
                return "Feedback for \(appName ?? "") \(version ?? "") - \(UIDevice.current.name) - \(UIDevice.current.systemVersion)"
            }()

            if MFMailComposeViewController.canSendMail() {
                let composeController = MFMailComposeViewController()
                composeController.mailComposeDelegate = self
                composeController.setToRecipients([recipient])
                composeController.setSubject(subject)

                present(composeController, animated: true)
            } else if let emailUrl = createEmailUrl(to: recipient, subject: subject, body: "") {
                UIApplication.shared.open(emailUrl)
            } else {
                let alertController = UIAlertController(title: "Cannot Send Mail", message: "Please set up an email account in order to send a support request email.", preferredStyle: .alert)

                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alertController.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }))
                present(alertController, animated: true)
            }
        }
    }

    // MARK: - rotation
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .all
        } else {
            return .portrait
        }
    }

    override var shouldAutorotate: Bool {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return true
        } else {
            return false
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < sections.count {
            let indexSection = sections[section]
            return indexSection.rows?.count ?? 0
        }

        return 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < sections.count {
            let indexSection = sections[section]
            return indexSection.title
        }
        return nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let genericCellFontSize: CGFloat = 18.0

        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: GenericTVCell.self))

        if
            let generic = cell as? GenericTVCell,
            indexPath.section < sections.count,
            let rows = sections[indexPath.section].rows,
            indexPath.row < rows.count
        {
            let indexRow = rows[indexPath.row]

            generic.label?.numberOfLines = 2
            generic.label?.textAlignment = .center
            generic.label?.lineBreakMode = .byWordWrapping

            if
                let appConfig = appConfig,
                let settings = settings
            {
                generic.label?.font = Helper.defaultFont(withSize: genericCellFontSize,
                                                         forTextStyle: .title2,
                                                         appConfig: appConfig,
                                                         settings: settings)
            }

            generic.label?.text = indexRow.title
            generic.label?.highlightedTextColor = UIColor.white
        }

        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section < sections.count else {
            return
        }

        let indexSection = sections[indexPath.section]

        if
            let indexRow = indexSection.rows?[indexPath.row],
            let action = indexRow.action,
            action == "sendFeedback"
        {
            sendFeedback()
            return
        }

        guard
            indexPath.row < indexSection.rows?.count ?? 0,
            let indexRow = indexSection.rows?[indexPath.row],
            let name = indexRow.storyboardName,
            let id = indexRow.storyboardID,
            name.count > 0,
            id.count > 0
        else
        {
            return
        }

        let storyboard = UIStoryboard(name: name, bundle: Helper.songsForWorshipBundle())
        let viewController = storyboard.instantiateViewController(withIdentifier: id)

        if var hasSongs = viewController as? HasSongsManager {
            hasSongs.songsManager = songsManager
        }

        if var hasSettings = viewController as? HasSettings {
            hasSettings.settings = settings
        }

        if var hasAppConfig = viewController as? HasAppConfig {
            hasAppConfig.appConfig = appConfig
        }

        if
            let filename = indexRow.filename,
            let filetype = indexRow.filetype,
            var hasFileInfo = viewController as? HasFileInfo,
            let appConfig = appConfig
        {
            hasFileInfo.fileInfo = (filename, filetype, appConfig.directory)
        }

        if
            let viewController = viewController as? IndexVC,
            let index = indexRow.index
        {
            viewController.sections = index
        }

        if let viewController = viewController as? SongDetailVCDelegate {
            detailVC()?.delegate = viewController
        }

        viewController.title = indexRow.title

        if UIDevice.current.userInterfaceIdiom != .pad {
            navigationController?.pushViewController(viewController, animated: true)
            songsManager?.setcurrentSong(nil, songsToDisplay: nil)
        } else {
            if viewController is AnyIndexVC {
                navigationController?.pushViewController(viewController, animated: true)
            } else if let detail = splitViewController?.viewController(for: .secondary) {
                if let detailNav = detail as? UINavigationController {
                    detailNav.setViewControllers([viewController], animated: false)
                } else {
                    splitViewController?.setViewController(viewController, for: .secondary)
                }
            }
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true)
    }

}

extension IndexVC: ThemeObserver {
    func themeDidChange(_ notification: Notification) {
        configureNavBar()
    }
}

extension IndexVC: HasAppConfig {}

extension IndexVC: HasSettings {}
