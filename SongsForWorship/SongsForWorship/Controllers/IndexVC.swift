//
//  IndexVC.swift
//  PsalmsForWorship
//
//  Created by PHILIP LODEN on 12/28/10.
//  Copyright © 2017 Deo Volente, LLC. All rights reserved.
//

extension Bundle {
    var appName: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    }
    var version: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}

import MessageUI

class IndexVC: UIViewController, HasSongsManager, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate, HasSettings {
    var settings: Settings? {
        didSet {
            oldValue?.removeObserver(forSettings: self)
            settings?.addObserver(forSettings: self)
        }
    }
    var songsManager: SongsManager?
    var sections: [IndexSection]!
    
    enum FeedbackSectionRow: Int {
        case settings = 0, feedback, count
    }
    
    @IBOutlet private var indexTableView: UITableView?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = ""
        configureNavBar()
        
        indexTableView?.register(UINib(nibName: NSStringFromClass(SongTVCell.self.self), bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: NSStringFromClass(SongTVCell.self.self))
        indexTableView?.register(UINib(nibName: "GenericTVCell", bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: "GenericTVCell")
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
        
        let selection = indexTableView?.indexPathForSelectedRow
        if selection == nil {
            return
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            if selection?.section == 0 {
                if let selection = selection {
                    indexTableView?.deselectRow(at: selection, animated: true)
                }
            }
        } else {
            if let selection = selection {
                indexTableView?.deselectRow(at: selection, animated: true)
            }
        }
    }
    
    // MARK: - Helper methods
    
    func configureNavBar() {
        if UIDevice.current.userInterfaceIdiom != .pad {
            if settings?.theme == .defaultLight {
                let navbarLogo = UIImageView(image: UIImage(named: "nav_bar_icon", in: nil, with: .none))
                navigationItem.titleView = navbarLogo
            } else if settings?.theme == .white {
                let templateImage = UIImage(named: "nav_bar_icon", in: nil, with: .none)!.withRenderingMode(.alwaysTemplate)
                let navbarLogo = UIImageView(image: templateImage)
                navbarLogo.tintColor = UIColor(named: "NavBarBackground")!
                navigationItem.titleView = navbarLogo
            }  else if settings?.theme == .night {
                let templateImage = UIImage(named: "nav_bar_icon", in: nil, with: .none)!.withRenderingMode(.alwaysTemplate)
                let navbarLogo = UIImageView(image: templateImage)
                navbarLogo.tintColor = .white
                navigationItem.titleView = navbarLogo
            }
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
                    let nc = vc as? UINavigationController,
                    let detail = nc.topViewController as? SongDetailVC
                {
                    return detail
                }
            }
        }
        return nil
    }
    
    class func favoriteSongs(songsManager: SongsManager) -> [Song] {
        let favs = FavoritesSyncronizer.favoriteSongNumbers(songsManager: songsManager).compactMap { songsManager.songForNumber($0) }
        return favs
    }
    
    func tableView(_ tableView: UITableView?, didSelectFeedbackSectionRowWith index: Int) {
        if let rowIndex = FeedbackSectionRow(rawValue: index) {
            switch rowIndex {
            case .feedback:
                let recipient = "contact@deovolentellc.com"
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
                break
            case .settings:
                if let vc = SettingsVC.pfw_instantiateFromStoryboard() {
                    navigationController?.pushViewController(vc, animated: true)
                }
            default:
                break
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
        if UIDevice.current.userInterfaceIdiom == .pad || !UIDevice.current.orientation.isLandscape {
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let genericCellFontSize: CGFloat = 18.0
        
        var cell: UITableViewCell? = nil
        
        if indexPath.section < sections.count {
            let indexSection = sections[indexPath.section]
            
            if indexPath.row < indexSection.rows?.count ?? 0 {
                let indexRow = indexSection.rows?[indexPath.row]
                
                let generic = tableView.dequeueReusableCell(withIdentifier: "GenericTVCell") as? GenericTVCell
                generic?.textLabel?.textColor = UIColor.label
                generic?.textLabel?.font = Helper.defaultFont(withSize: genericCellFontSize, forTextStyle: .title2)
                generic?.textLabel?.text = indexRow?.title //songsManager?.songCollections.compactMap { $0.displayName } .joined(separator: " & ")
                generic?.textLabel?.highlightedTextColor = UIColor.white
                cell = generic
            }
        }
                
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section < sections.count {
            let indexSection = sections[indexPath.section]
            
            if indexPath.row < indexSection.rows?.count ?? 0 {
                if
                    let indexRow = indexSection.rows?[indexPath.row],
                    let name = indexRow.storyboardName,
                    let id = indexRow.storyboardID
                {
                    let sb = UIStoryboard(name: name, bundle: Helper.songsForWorshipBundle())
                    let vc = sb.instantiateViewController(withIdentifier: id)
                    
                    if var hasSongs = vc as? HasSongsManager {
                        hasSongs.songsManager = songsManager
                    }
                    
                    if
                        let filename = indexRow.filename,
                        let filetype = indexRow.filetype,
                        var hasFileInfo = vc as? HasFileInfo,
                        let app = UIApplication.shared.delegate as? PsalterAppDelegate                        
                    {
                        hasFileInfo.fileInfo = (filename, filetype, app.appConfig.directory)
                    }
                    
                    if
                        let vc = vc as? IndexVC,
                        let index = indexRow.index
                    {
                        vc.sections = index
                    }
                    
                    if let vc = vc as? SongDetailVCDelegate {
                        detailVC()?.delegate = vc
                    }
                    
                    vc.title = indexRow.title
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }        
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true)
    }
    
}

extension IndexVC: SettingsObserver {
    func settingsDidChange(_ notification: Notification) {
        configureNavBar()
    }
}
