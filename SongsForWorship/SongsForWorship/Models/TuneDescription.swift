//
//  TuneDescription.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 1/2/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation

public enum TuneDescriptionMediaType {
    case midi, mp3
}

public class TuneDescription: NSObject {
    let length: String?
    let title: String
    let url: URL
    let mediaType: TuneDescriptionMediaType
    
    public init(length: String?, title: String, url: URL, mediaType: TuneDescriptionMediaType) {
        self.length = length
        self.title = title
        self.url = url
        self.mediaType = mediaType
        super.init()
    }
}
