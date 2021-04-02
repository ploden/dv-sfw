//
//  HasSettings.swift
//  SongsForWorship
//
//  Created by Philip Loden on 4/1/21.
//  Copyright © 2021 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol HasSettings {
    var settings: Settings? { get set }
}

extension HasSettings where Self: UIViewController {
    var settings: Settings? {
        if let settings = settings {
            return settings
        }
        if let app = UIApplication.shared.delegate as? PsalterAppDelegate {
            return app.settings
        }
        return nil
    }
}
