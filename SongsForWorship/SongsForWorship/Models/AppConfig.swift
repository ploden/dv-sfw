//
//  AppConfig.swift
//  SongsForWorship
//
//  Created by Phil Loden on 3/20/21. Licensed under the MIT license, as follows:
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

public struct AppConfig: Decodable {
    let index: [IndexSection]
    let copyright: String
    var copyrightWithDate: String {
        get {
            let yearComponent = Calendar.current.component(Calendar.Component.year, from: Date())
            return String(format: "© %ld \(copyright).", yearComponent)
        }
    }
    let directory: String
    let defaultFont: String
    let defaultFontDisplayName: String
    let defaultBoldFont: String
    let songCollections: [SongCollectionConfig]
    let soundFonts: [SoundFontConfig]
    let tuneRecordings: Bool
    let shouldShowAdditionalTunes: Bool
    let shouldShowPlaybackRateSegmentedControl: Bool
    let pdfRenderingConfigsForiPhone: [PDFRenderingConfig]
    let pdfRenderingConfigsForiPad: [PDFRenderingConfig]
    let shouldHideSheetMusicForCopyrightedTunes: Bool
    let customClasses: [CustomClassConfig]
    let sendFeedbackEmailAddress: String
    public let versionsToPurgeTunes: [String]?
    var tunesLoaderClass: TunesLoader.Type {
        get {
            let customClassConfig = customClasses.first(where: { $0.baseName == String(describing: TunesLoader.self) })!
            let appName = Bundle.main.appName!
            let customClass = Bundle.main.classNamed("\(appName).\(customClassConfig.customName)") as! TunesLoader.Type
            return customClass
        }
    }
    var songClass: Song.Type {
        get {
            let customClassConfig = customClasses.first(where: { $0.baseName == String(describing: (Song).self) })!
            let appName = Bundle.main.appName!
            let customClass = Bundle.main.classNamed("\(appName).\(customClassConfig.customName)") as! Song.Type
            return customClass
        }
    }
    var songTVCellViewModelClass: SongTVCellViewModelProtocol.Type {
        get {
            let customClassConfig = customClasses.first(where: { $0.baseName == "SongTVCellViewModel" })!
            let appName = Bundle.main.appName!
            let customClass = Bundle.main.classNamed("\(appName).\(customClassConfig.customName)") as! SongTVCellViewModelProtocol.Type
            return customClass
        }
    }
    var metreCVCellViewModelClass: MetreCVCellViewModelProtocol.Type {
        get {
            let customClassConfig = customClasses.first(where: { $0.baseName == "MetreCVCellViewModel" })!
            let appName = Bundle.main.appName!
            let customClass = Bundle.main.classNamed("\(appName).\(customClassConfig.customName)") as! MetreCVCellViewModelProtocol.Type
            return customClass
        }
    }
    
    enum CodingKeys: CodingKey {
        case index
        case copyright
        case directory
        case defaultFont
        case defaultFontDisplayName
        case defaultBoldFont
        case songCollections
        case soundFonts
        case tuneRecordings
        case shouldShowAdditionalTunes
        case shouldShowPlaybackRateSegmentedControl
        case pdfRenderingConfigsForiPhone
        case pdfRenderingConfigsForiPad
        case shouldHideSheetMusicForCopyrightedTunes
        case customClasses
        case sendFeedbackEmailAddress
        case versionsToPurgeTunes
    }    
}
