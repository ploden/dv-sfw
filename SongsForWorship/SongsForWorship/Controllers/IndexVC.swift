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

class IndexVC: UIViewController, HasSongsManager, DetailVCDelegate, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate {
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
        navigationItem.backBarButtonItem?.tintColor = .white
        navigationController?.navigationBar.barTintColor = Helper.tintColor()
        
        indexTableView?.register(UINib(nibName: NSStringFromClass(SongTVCell.self.self), bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: NSStringFromClass(SongTVCell.self.self))
        indexTableView?.register(UINib(nibName: "GenericTVCell", bundle: Helper.songsForWorshipBundle()), forCellReuseIdentifier: "GenericTVCell")
        
        if UIDevice.current.userInterfaceIdiom != .pad {
            let navbarLogo = UIImageView(image: UIImage(named: "nav_bar_icon", in: nil, with: .none))
            navigationItem.titleView = navbarLogo
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        indexTableView?.reloadData()
        
        if UIDevice.current.userInterfaceIdiom != .pad {
            NotificationCenter.default.post(name: NSNotification.Name("stop playing"), object: nil)
        }
        
        if let detail = detailVC() {
            detail.delegate = self
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
    
    class func favoriteSongs(_ allSongs: [Song]?) -> [Song] {
        var songs = [Song]()
        
        let favs = FavoritesSyncronizer.favorites()
        
        for i in 0..<favs.count {
            let songIndex = favs[i]
            let song = SongsManager.songAtIndex(songIndex, allSongs: allSongs)
            
            if let song = song {
                songs.append(song)
            }
        }

        return songs.sorted {
            $0.index < $1.index
        }
    }
    
    class func favoritePsalmForIndexPath(_ indexPath: IndexPath, allSongs: [Song]?) -> Song? {
        let favoriteSongs = IndexVC.favoriteSongs(allSongs)
        
        let idx = indexPath.row
        
        if idx < favoriteSongs.count {
            return favoriteSongs[idx]
        }
        return nil
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
                if let vc = SettingsTableVC.pfw_instantiateFromStoryboard() {
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
                        let app = UIApplication.shared.delegate as? PsalterAppDelegate,
                        let directory = app.getAppConfig()["Directory"] as? String
                    {
                        hasFileInfo.fileInfo = (filename, filetype, directory)
                    }
                    
                    if
                        let vc = vc as? IndexVC,
                        let index = indexRow.index
                    {
                        vc.sections = index
                    }
                    
                    if let vc = vc as? DetailVCDelegate {
                        detailVC()?.delegate = vc
                    }
                    
                    vc.title = indexRow.title
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if
            let indexTableView = indexTableView,
            indexPath.section == 1
        {
            NotificationCenter.default.removeObserver(indexTableView)
            
            indexTableView.beginUpdates()
            
            if indexPath.row == indexTableView.numberOfRows(inSection: indexPath.section) - 1 {
                if indexPath.row == 0 {
                    indexTableView.reloadData()
                } else {
                    indexTableView.deleteRows(at: [indexPath], with: .fade)
                }
            } else {
                indexTableView.deleteRows(at: [indexPath], with: .bottom)
            }
            
            if let song = IndexVC.favoritePsalmForIndexPath(indexPath, allSongs: songsManager?.currentCollection?.songs) {
                FavoritesSyncronizer.removeFromFavorites(song)
            }
            
            indexTableView.endUpdates()
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true)
    }
    
    // MARK: - DetailVCDelegate
    func songsToDisplayForDetailVC(_ detailVC: DetailVC?) -> [Song]? {
        return IndexVC.favoriteSongs(songsManager?.currentCollection?.songs)
    }
    
    func isSearchingForDetailVC(_ detailVC: DetailVC?) -> Bool {
        return false
    }
}
