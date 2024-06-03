//
//  TuneDescription.swift
//  SongsForWorship
//
//  Created by Phil Loden on 1/2/20. Licensed under the MIT license, as follows:
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

public enum TuneDescriptionMediaType {
    case localMIDI, localMP3, musicLibrary, appleMusic
}

/*
public enum TuneDescriptionMediaType {
    case midi, mp3, localMidi
}
*/

/*
 public struct TuneDescription: TuneDescriptionProtocol {
 public var lengthString: String?
 public var length: TimeInterval?
 public var url: URL?
 public let title: String
 public let composer: String?
 public let copyright: String?
 public let mediaType: TuneDescriptionMediaType

 public init(lengthString: String? = nil,
 length: TimeInterval? = nil,
 title: String,
 composer: String? = nil,
 copyright: String? = nil,
 url: URL,
 mediaType: TuneDescriptionMediaType)
 {
 self.lengthString = lengthString
 self.length = length
 self.title = title
 self.composer = composer
 self.copyright = copyright
 self.url = url
 self.mediaType = mediaType
 }
 }
 */
