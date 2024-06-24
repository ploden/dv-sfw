//
//  SongCollection.swift
//  SongsForWorship
//
//  Created by Philip Loden on 7/26/23.
//  Copyright © 2023 Deo Volente, LLC. All rights reserved.
//

import Foundation
import QuartzCore

/// A type that represents a collection of songs.
///
/// TODO: The use of generics here is legacy code,
/// and might no longer make sense.
public struct SongCollection<T: Song>: Equatable {
    public static func == (lhs: SongCollection<T>, rhs: SongCollection<T>) -> Bool {
        return false
    }

    public let jsonFilename: String
    public let pdfFilename: String
    public let directory: String
    public let displayName: String
    public let pdf: CGPDFDocument
    public let sections: [SongCollectionSection]
    public var pdfRenderingConfigsForiPhone: [PDFRenderingConfig] = [PDFRenderingConfig]()
    public var pdfRenderingConfigsForiPad: [PDFRenderingConfig] = [PDFRenderingConfig]()
    public let tuneInfos: [SongCollectionTuneInfo]
    public let songs: [T]

    init(songs: [T],
         directory: String,
         collectionConfig: SongCollectionConfig,
         pdfRenderingConfigsForiPhone: [PDFRenderingConfig],
         pdfRenderingConfigsForiPad: [PDFRenderingConfig])
    {
        self.jsonFilename = collectionConfig.jsonFilename
        self.displayName = collectionConfig.displayName
        self.pdfFilename = collectionConfig.pdfFilename

        self.directory = directory

        var collectionSections = [SongCollectionSection]()

        for section in collectionConfig.sections {
            let newSection = SongCollectionSection(title: section.title, count: section.count)
            collectionSections.append(newSection)
        }

        self.sections = collectionSections

        let tuneInfos: [SongCollectionTuneInfo]? = collectionConfig.tunes.compactMap {
            return SongCollectionTuneInfo(title: $0.title, directory: $0.directory, fileType: $0.filetype, filenameFormat: $0.filenameFormat)
        }

        self.tuneInfos = tuneInfos ?? [SongCollectionTuneInfo]()

        self.pdf = CGPDFDocument(URL(fileURLWithPath: Bundle.main.path(forResource: pdfFilename, ofType: "pdf", inDirectory: directory)!) as CFURL)!

        self.songs = songs

        self.pdfRenderingConfigsForiPhone = pdfRenderingConfigsForiPhone

        self.pdfRenderingConfigsForiPad = pdfRenderingConfigsForiPad
    }

    func song(for number: String?) -> T? {
        return songs.first(where: { $0.number == number })
    }
}
