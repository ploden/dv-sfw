//
//  AppConfig.swift
//  SongsForWorship
//
//  Created by Philip Loden on 3/20/21.
//  Copyright © 2021 Deo Volente, LLC. All rights reserved.
//

import Foundation

public struct AppConfig: Decodable {
    let index: [IndexSection]
    let copyright: String
    let appID: String?
    let facebookPageURL: String?
    let directory: String
    let defaultFont: String
    let defaultFontDisplayName: String
    let defaultBoldFont: String
    let songCollections: [SongCollectionConfig]
    let soundFonts: [SoundFontConfig]
    let tuneRecordings: Bool
    let shouldShowAdditionalTunes: Bool
    let shouldShowPlaybackRateSegmentedControl: Bool
    let pdfRenderingConfigs_iPhone: [PDFRenderingConfig]
    let pdfRenderingConfigs_iPad: [PDFRenderingConfig]
    let shouldHideSheetMusicForCopyrightedTunes: Bool
    let customClasses: [CustomClassConfig]
    let sendFeedbackEmailAddress: String
    public let versionsToPurgeTunes: [String]
    
    /*
    func customClass(forProtocol aProtocol: Protocol) -> AnyClass {
        if
            let customClassConfig = customClasses.first(where: { $0.baseName == String(describing: aProtocol.self) }),
            let appName = Bundle.main.appName,
            let customClass = Bundle.main.classNamed("\(appName).\(customClassConfig.customName)")// as? aProtocol.Type
        {
            return customClass
        }
        
        return aProtocol
    }
     */
}
