//
//  TextViewVC.swift
//  SongsForWorship
//
//  Created by Philip Loden on 8/12/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

class TextViewVC: UIViewController, HasFileURL {
    private var text: String?
    @IBOutlet weak private var textView: UITextView?
    var fileURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let fileURL = fileURL {
            text = TextViewVC.readText(fromFileURL: fileURL)
            textView?.text = text
        }
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
}
