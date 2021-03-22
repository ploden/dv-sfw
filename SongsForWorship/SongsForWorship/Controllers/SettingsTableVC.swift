//
//  SettingsTableVC.swift
//  SongsForWorship
//
//  Created by Philip Loden on 9/12/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

class SettingsTableVC: UITableViewController {

    enum TableSection: Int {
        case textSize = 0, soundFonts, count
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return TableSection.count.rawValue
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let section = TableSection(rawValue: section) {
            switch section {
            case .textSize:
                return 1
            case .soundFonts:
                if let app = UIApplication.shared.delegate as? PsalterAppDelegate {
                    return app.appConfig.soundFonts.count
                }
            default:
                return 0
            }
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsTVCell") as? GenericTVCell
        cell?.textLabel?.textAlignment = .left
        
        if let section = TableSection(rawValue: indexPath.section) {
            switch section {
            case .textSize:
                cell?.textLabel?.text = "Use System Fonts"
                cell?.detailTextLabel?.text = "Use system fonts to increase text size"
                let theSwitch = UISwitch()
                
                if
                    let app = UIApplication.shared.delegate as? PsalterAppDelegate
                {
                    theSwitch.isOn = app.settings.shouldUseSystemFonts
                }
                
                theSwitch.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
                cell?.accessoryView = theSwitch
            case .soundFonts:
                if
                    let app = UIApplication.shared.delegate as? PsalterAppDelegate,
                    indexPath.row < app.settings.soundFonts.count
                {
                    let font = app.settings.soundFonts[indexPath.row]                    
                    cell?.textLabel?.text = font.title
                    cell?.accessoryType = font == app.settings.selectedSoundFontOrDefault() ? .checkmark : .none
                }
            default:
                break
            }
        }
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let section = TableSection(rawValue: indexPath.section) {
            switch section {
            case .soundFonts:
                if
                    let app = UIApplication.shared.delegate as? PsalterAppDelegate,
                    indexPath.row < app.settings.soundFonts.count
                {
                    let font = app.settings.soundFonts[indexPath.row]
                    app.settings.selectedSoundFont = font
                    tableView.reloadData()
                }
            default:
                break
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
        
    @IBAction func switchValueChanged(sender: Any) {
        if let aSwitch = sender as? UISwitch {
            if
                let app = UIApplication.shared.delegate as? PsalterAppDelegate
            {
                app.settings.shouldUseSystemFonts = aSwitch.isOn
            }
        }
    }
}
