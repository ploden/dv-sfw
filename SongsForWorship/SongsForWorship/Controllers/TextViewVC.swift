//
//  TextViewVC.swift
//  SongsForWorship
//
//  Created by Philip Loden on 8/12/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit
import SwiftyMarkdown
import SwiftTheme

typealias FileInfo = (String, String, String)

class TextViewVC: UIViewController, HasFileInfo {
    var fileInfo: FileInfo?
    @IBOutlet weak private var textView: UITextView? {
        didSet {
            textView?.font = Helper.defaultFont(withSize: 12.0, forTextStyle: .body)
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
                textView?.attributedText = Self.readMarkdown(fromFileURL: url)
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
        var jsonString: String? = nil
        do {
            jsonString = try String(contentsOf: url, encoding: String.Encoding.utf8)
            let jsonData = jsonString?.data(using: .utf8)
            
            do {
                if let jsonData = jsonData {
                    let dict: [String:AnyHashable]? = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [String:AnyHashable]
                    
                    if let dict = dict {
                        return dict["text"] as? String
                    }
                }
            } catch {}
        } catch {}
        return nil
    }
    
    class func readMarkdown(fromFileURL url: URL) -> NSAttributedString? {
        if let markdownString = try? String(contentsOf: url, encoding: String.Encoding.utf8) {
            let down = SwiftyMarkdown(string: markdownString)
            down.setFontNameForAllStyles(with: Helper.defaultFont(withSize: 12.0, forTextStyle: .body).fontName)
            let attributedString = down.attributedString()
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
            mutableAttributedString.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length: mutableAttributedString.length))
            return mutableAttributedString
            
        }
        return nil
    }
}
