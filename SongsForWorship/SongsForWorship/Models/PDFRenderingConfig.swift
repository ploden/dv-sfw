//
//  PDFRenderingConfig.swift
//  SongsForWorship
//
//  Created by Philip Loden on 4/4/21.
//  Copyright © 2021 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

enum PDFRenderingDeviceOrientation: String, Decodable {
    case portrait
    case landscape
    case landscapeLeft
    case landscapeRight
}

enum PDFRenderingPageOrientation: String, Decodable {
    case left = "left"
    case right = "right"
}

public struct PDFRenderingConfig: Decodable {
    let deviceName: String?
    let deviceOrientation: PDFRenderingDeviceOrientation
    let deviceType: String?
    let pageOrientation: PDFRenderingPageOrientation
    let scale: CGFloat
    let screenHeight: CGFloat?
    let screenWidth: CGFloat?
    let translateX: CGFloat
    let translateY: CGFloat
}
