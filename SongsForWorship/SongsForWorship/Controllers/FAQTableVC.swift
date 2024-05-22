//
//  FAQTableVC.swift
//  SongsForWorship
//
//  Created by elendil on 1/7/17. Licensed under the MIT license, as follows:
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

class FAQTableVC: UITableViewController, HasFileInfo {
    var settings: Settings!
    var appConfig: AppConfig!
    var fileInfo: FileInfo?
    private var faqs: [FAQ]?

    override func viewDidLoad() {
        super.viewDidLoad()

        if
            let fileInfo = fileInfo,
            let path = Bundle.main.path(forResource: fileInfo.0, ofType: fileInfo.1, inDirectory: fileInfo.2)
        {
            let url = URL(fileURLWithPath: path)
            faqs = FAQTableVC.readFAQs(fromFileURL: url)
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

        if
            let appConfig = appConfig,
            let settings = settings
        {
            cell?.questionLabel?.font = Helper.defaultBoldFont(withSize: 14.0, forTextStyle: .body, appConfig: appConfig, settings: settings)
            cell?.answerLabel?.font = Helper.defaultFont(withSize: 14.0, forTextStyle: .body, appConfig: appConfig, settings: settings)
        }

        return cell!
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    class func readFAQs(fromFileURL url: URL) -> [FAQ] {
        guard let jsonData = try? Data(contentsOf: url) else { return [FAQ]() }

        let decoder = JSONDecoder()

        return (try? decoder.decode([FAQ].self, from: jsonData)) ?? [FAQ]()
    }
}

extension FAQTableVC: HasAppConfig {}

extension FAQTableVC: HasSettings {}
