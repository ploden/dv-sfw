//
//  FAQTableVC.swift
//  PsalmsForWorship
//
//  Created by elendil on 1/7/17.
//  Copyright © 2017 Deo Volente, LLC. All rights reserved.
//

import UIKit
import SwiftTheme

class FAQTableVC: UITableViewController, HasFileInfo {
    var fileInfo: FileInfo?
    private var faqs: [FAQ]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if
            let fileInfo = fileInfo,
            let path = Bundle.main.path(forResource: fileInfo.0, ofType: fileInfo.1, inDirectory: fileInfo.2)
        {
            let url = URL(fileURLWithPath: path)
            faqs = try? JSONDecoder().decode([FAQ].self, from: Data(contentsOf: url))
        }
        
        tableView.rowHeight = UITableView.automaticDimension
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
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return faqs?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FAQTVCell", for: indexPath) as? FAQTVCell
        
        let faq = faqs?[indexPath.row]
        
        cell?.questionLabel?.text = faq?.question
        cell?.answerLabel?.text = faq?.answer
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
        
}
