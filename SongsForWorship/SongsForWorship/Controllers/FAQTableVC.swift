//
//  FAQTableVC.swift
//  PsalmsForWorship
//
//  Created by elendil on 1/7/17.
//  Copyright © 2017 Deo Volente, LLC. All rights reserved.
//

import UIKit

class FAQTableVC: UITableViewController, HasFileURL {
    private var faqs: [FAQ]?
    var fileURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let fileURL = fileURL {
            faqs = FAQTableVC.readFAQs(fromFileURL: fileURL)
        }
        
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
    
    class func readFAQs(fromFileURL url: URL) -> [FAQ] {
        var jsonString: String? = nil
        do {
            jsonString = try String(contentsOf: url, encoding: String.Encoding.utf8)
        } catch {
        }
        
        let jsonData = jsonString?.data(using: .utf8)
        var dictsArray: [AnyHashable]? = nil
        do {
            if let jsonData = jsonData {
                dictsArray = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [AnyHashable]
            }
        } catch {}
        
        var faqsArray = [FAQ]()
        
        if let dictsArray = dictsArray {
            for dict in dictsArray {
                guard let dict = dict as? [AnyHashable : Any] else {
                    continue
                }
                
                if
                    let question = dict["question"] as? String,
                    let answer = dict["answer"] as? String
                {
                    let faq = FAQ(question: question, answer: answer)
                    faqsArray.append(faq)
                }
            }
        }
        
        return faqsArray
    }
}
