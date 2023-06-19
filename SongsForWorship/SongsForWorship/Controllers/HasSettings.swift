//
//  HasSettings.swift
//  SongsForWorship
//
//  Created by Philip Loden on 4/1/21.
//  Copyright © 2021 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol HasSettings: AnyObject {
    var settings: Settings? { get set }
}
