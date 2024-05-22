//
//  Tune.swift
//  SongsForWorship
//
//  Created by Phil Loden on 8/22/20. Licensed under the MIT license, as follows:
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

public struct Tune {
    public var id: Int?
    public var name: String
    public var nameWithoutMeter: String?
    public var composer: Composer?
    public var composerID: Composer.ID?
    public var composerCopyright: String?
    public var composerDate: String?
    public var isCopyrighted: Bool = false
    public var meter: String?
    public var songNumbers: [String] = [String]()

    public init(id: Int, name: String, nameWithoutMeter: String? = nil, composer: Composer? = nil, composerID: Composer.ID? = nil, composerCopyright: String? = nil, composerDate: String? = nil, isCopyrighted: Bool = false, meter: String? = nil, songNumbers: [String]? = nil) {
        self.id = id
        self.name = name
        self.nameWithoutMeter = nameWithoutMeter
        self.composer = composer
        self.composerID = composerID
        self.composerCopyright = composerCopyright
        self.composerDate = composerDate
        self.isCopyrighted = isCopyrighted
        self.meter = meter
        self.songNumbers = songNumbers ?? [String]()
    }

    public func new(with composer: Composer?) -> Tune {
        var newTune = self
        newTune.composer = composer
        return newTune
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case composerID = "composer_id"
        case composerDate = "composer_date"
        case meter
        case songNumbers = "psalms"
    }
}

extension Tune: Decodable {}
