//
//  Tune.swift
//  SongsForWorship
//
//  Created by Philip Loden on 8/22/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation

public struct Tune {
    public var name: String
    public var nameWithoutMeter: String?
    public var composer: Composer?
    public var composerCopyright: String?
    public var composerDate: String?
    public var isCopyrighted: Bool = false
    public var meter: String?
    
    public init(name: String, nameWithoutMeter: String?, composer: Composer?, composerDate: String?, composerCopyright: String?, isCopyrighted: Bool, meter: String?) {
        self.name = name
        self.nameWithoutMeter = nameWithoutMeter
        self.composer = composer
        self.composerDate = composerDate
        self.composerCopyright = composerCopyright
        self.isCopyrighted = isCopyrighted
        self.meter = meter
    }
}
