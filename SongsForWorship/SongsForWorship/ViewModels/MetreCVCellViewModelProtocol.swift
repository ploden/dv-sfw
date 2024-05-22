//
//  MetreCVCellViewModelProtocol.swift
//  SongsForWorship
//
//  Created by Philip Loden on 7/27/23.
//  Copyright © 2023 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

public protocol MetreCVCellViewModelProtocol {
    var title: String { get }
    var attributedMetreText: NSAttributedString { get }
    var leftText: String { get }
    var rightText: String { get }
    var versesText: String? { get }
    var copyrightText: String? { get }
    var metreLabelFont: UIFont { get }
    var titleLabelFont: UIFont { get }
    var copyrightLabelFont: UIFont { get }

    init(_ song: Song, copyrightText: String?, settings: Settings, appConfig: AppConfig)
}
