//
//  TextViewVC.swift
//  SongsForWorship
//
//  Created by Phil Loden on 8/12/20. Licensed under the MIT license, as follows:
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

import Foundation
import UIKit
import SwiftyMarkdown
import SwiftTheme

typealias FileInfo = (filename: String, filetype: String, directory: String)

class TextViewVC: UIViewController {
    var appConfig: AppConfig!
    var settings: Settings!
    var fileInfo: FileInfo?
    @IBOutlet weak private var textView: UITextView? {
        didSet {
            if
                let appConfig = appConfig,
                let settings = settings
            {
                textView?.font = Helper.defaultFont(withSize: 12.0, forTextStyle: .body, appConfig: appConfig, settings: settings)
            }
        }
    }
    var fileURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()

        if
            let fileInfo = fileInfo,
            let path = Bundle.main.path(forResource: fileInfo.0, ofType: fileInfo.1, inDirectory: fileInfo.2)
        {
            let url = URL(fileURLWithPath: path)

            if fileInfo.1 == "json" {
                textView?.text = Self.readText(fromFileURL: url)
            } else if fileInfo.1 == "md" {
                textView?.attributedText = Self.readMarkdown(fromFileURL: url, appConfig: appConfig, settings: settings)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: animated)
        textView?.contentOffset = .zero
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

    class func readText(fromFileURL url: URL) -> String? {
        var jsonString: String?
        do {
            jsonString = try String(contentsOf: url, encoding: String.Encoding.utf8)
            let jsonData = jsonString?.data(using: .utf8)

            do {
                if let jsonData = jsonData {
                    let dict: [String: AnyHashable]? = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [String: AnyHashable]

                    if let dict = dict {
                        return dict["text"] as? String
                    }
                }
            } catch {}
        } catch {}
        return nil
    }

    class func readMarkdown(fromFileURL url: URL, appConfig: AppConfig?, settings: Settings?) -> NSAttributedString? {
        guard let markdownString = try? String(contentsOf: url, encoding: String.Encoding.utf8) else { return nil }

        let down = SwiftyMarkdown(string: markdownString)

        if
            let appConfig = appConfig,
            let settings = settings
        {
            down.setFontNameForAllStyles(with: Helper.defaultFont(withSize: 12.0, forTextStyle: .body, appConfig: appConfig, settings: settings).fontName)
        }
        
        let attributedString = down.attributedString()
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        mutableAttributedString.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length: mutableAttributedString.length))
        return mutableAttributedString
    }
}

extension TextViewVC: HasFileInfo {}

extension TextViewVC: HasAppConfig {}

extension TextViewVC: HasSettings {}
