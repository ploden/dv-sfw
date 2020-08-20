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

enum PFWIndexTableViewSection : Int {
    case _Psalms = 0
    case _Misc = 1
    case _Feedback = 2
    case _Count = 3
}

class IndexVC: UIViewController, DetailVCDelegate, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate {
    var songsManager: SongsManager!
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
            let navbarLogo = UIImageView(image: UIImage(named: "nav_bar_icon", in: Helper.songsForWorshipBundle(), with: .none))
            navigationItem.titleView = navbarLogo
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        if MFMailComposeViewController.canSendMail() {
            let subjectString: String = {
                let appName = Bundle.main.appName
                let version = Bundle.main.version
                
                return "Feedback for \(appName ?? "") \(version ?? "") - \(UIDevice.current.name) - \(UIDevice.current.systemVersion)"
            }()
                        
            let composeController = MFMailComposeViewController()
            composeController.mailComposeDelegate = self
            composeController.setToRecipients(["contact@deovolentellc.com"])
            composeController.setSubject(subjectString)
            
            present(composeController, animated: true)
        } else {
            let alertController = UIAlertController(title: "Cannot Send Mail", message: "You need to set up an email account in order to send a support request email.", preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }))
            present(alertController, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView?, didSelectMiscSectionRowWith index: Int) {
        if
            let app = UIApplication.shared.delegate as? PsalterAppDelegate,
            let indexItems = app.getAppConfig()["Index"] as? [Any],
            index < indexItems.count
        {
            let item = indexItems[index]
            
            if
                let item = item as? [String:String],
                let name = item["Storyboard name"],
                let id = item["Storyboard ID"]
            {
                let sb = UIStoryboard(name: name, bundle: Helper.songsForWorshipBundle())
                let vc = sb.instantiateViewController(withIdentifier: id)
                
                if var hasSongs = vc as? HasSongsManager {
                    hasSongs.songsManager = songsManager
                }
                
                if
                    let jsonName = item["json_name"],
                    var hasFileURL = vc as? HasFileURL,
                    let app = UIApplication.shared.delegate as? PsalterAppDelegate,
                    let directory = app.getAppConfig()["Directory"] as? String,
                    let path = Bundle.main.path(forResource: jsonName, ofType: "json", inDirectory: directory)
                {
                    hasFileURL.fileURL = URL(fileURLWithPath: path)
                }
                
                navigationController?.pushViewController(vc, animated: true)
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
        return PFWIndexTableViewSection._Count.rawValue
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case PFWIndexTableViewSection._Misc.rawValue:
            if
                let app = UIApplication.shared.delegate as? PsalterAppDelegate,
                let indexItems = app.getAppConfig()["Index"] as? [Any]
            {
                return indexItems.count
            } else {
                return 0
            }
        case PFWIndexTableViewSection._Feedback.rawValue:
            return 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case PFWIndexTableViewSection._Misc.rawValue:
            return "Index"
        case PFWIndexTableViewSection._Feedback.rawValue:
            return "Feedback"
        default:
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let genericCellFontSize: CGFloat = 18.0
        
        var cell: UITableViewCell? = nil
        
        if indexPath.section == 0 {
            let generic = tableView.dequeueReusableCell(withIdentifier: "GenericTVCell") as? GenericTVCell
            generic?.textLabel?.textColor = UIColor.label
            generic?.textLabel?.font = generic?.textLabel?.font.withSize(genericCellFontSize)
            generic?.textLabel?.text = "Psalms"
            generic?.textLabel?.highlightedTextColor = UIColor.white
            cell = generic
        } else if indexPath.section == PFWIndexTableViewSection._Misc.rawValue || indexPath.section == PFWIndexTableViewSection._Feedback.rawValue {
            let generic = tableView.dequeueReusableCell(withIdentifier: "GenericTVCell") as? GenericTVCell
            generic?.textLabel?.textColor = UIColor.label
            generic?.textLabel?.font = generic?.textLabel?.font.withSize(genericCellFontSize)
            
            var cellText: String?
            
            if indexPath.section == PFWIndexTableViewSection._Misc.rawValue {
                if
                    let app = UIApplication.shared.delegate as? PsalterAppDelegate,
                    let indexItems = app.getAppConfig()["Index"] as? [Any],
                    indexPath.row < indexItems.count
                {
                    let item = indexItems[indexPath.row]
                    
                    if
                        let item = item as? [String:String],
                        let title = item["Title"]
                    {
                        cellText = title
                    }
                }
            } else if indexPath.section == PFWIndexTableViewSection._Feedback.rawValue {
                cellText = "Send Feedback"
            }
            
            generic?.textLabel?.text = cellText
            generic?.textLabel?.font = generic?.textLabel?.font.withSize(genericCellFontSize)
            generic?.textLabel?.highlightedTextColor = UIColor.white
            cell = generic
        }
        
        if cell != nil {
            return cell!
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            let vc = Helper.mainStoryboard_iPhone().instantiateViewController(withIdentifier: "PsalmIndexVC") as? SongIndexVC
            vc?.songsManager = songsManager
            detailVC()?.delegate = vc
            if let vc = vc {
                navigationController?.pushViewController(vc, animated: true)
            }
        } else if indexPath.section == PFWIndexTableViewSection._Misc.rawValue {
            self.tableView(tableView, didSelectMiscSectionRowWith: indexPath.row)
        } else if indexPath.section == PFWIndexTableViewSection._Feedback.rawValue {
            self.tableView(tableView, didSelectFeedbackSectionRowWith: indexPath.row)
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
            
            if let song = IndexVC.favoritePsalmForIndexPath(indexPath, allSongs: songsManager.currentCollection?.songs) {
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
        return IndexVC.favoriteSongs(songsManager.currentCollection?.songs)
    }
    
    func isSearchingForDetailVC(_ detailVC: DetailVC?) -> Bool {
        return false
    }
}
