//
//  TuneDescriptionProtocol.swift
//  SongsForWorship
//
//  Created by Philip Loden on 5/31/24.
//  Copyright © 2024 Deo Volente, LLC. All rights reserved.
//

import Foundation

public protocol TuneDescriptionProtocol {
    var lengthString: String? { get }
    var length: TimeInterval? { get }
    var title: String { get }
    var composer: String? { get }
    var copyright: String? { get }
    //var url: URL? { get }
    var mediaType: TuneDescriptionMediaType { get }
}
