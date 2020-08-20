//
//  UIViewController.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 4/23/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController: HasStoryboardName {

    @objc class var storyboardName: String? {
        get {
            return "Main_iPhone"
        }
    }
    
    func isForceTouchAvailable() -> Bool {
        if traitCollection.responds(to: Selector("forceTouchCapability")) {
            return traitCollection.forceTouchCapability == UIForceTouchCapability.available
        }
        
        return false
    }

    class func pfw_instantiateFromStoryboard() -> UIViewController? {
        if let sbName = self.storyboardName {
            let sb = UIStoryboard(name: sbName, bundle: Helper.songsForWorshipBundle())
            let className = String(describing: self)
            let vc = sb.instantiateViewController(withIdentifier: className)
            return vc
        }

        return nil
    }        
    
}
