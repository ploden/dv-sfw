//
//  TunesLoader.m
//  PsalmsForWorship
//
//  Created by PHILIP LODEN on 4/30/10.
//  Copyright 2010 Deo Volente, LLC. All rights reserved.
//

import UIKit
import AVFoundation
import StoreKit

protocol TunesLoader {
    static func filename(forTuneInfo tuneInfo: SongCollectionTuneInfo, song: Song) -> String?
    static func loadTunes(forSong aSong: Song, completion: @escaping (Bool, [TuneDescription], Error?) -> Void)
    static func defaultFilename(forTuneInfo tuneInfo: SongCollectionTuneInfo, song: Song) -> String? 
}

open class SFWTunesLoader: TunesLoader {
    
    class func lengthString(forDuration aDuration: TimeInterval) -> String {
        let length = aDuration
        let minutes = floor(length / 60)
        let seconds = Int(round(Double(length - (minutes * 60))))
        return String(format: "%zd:%02zd", minutes, seconds)
    }
    
    class func songNumberForPartsURLFromNumber(_ aSongNumber: String) -> String {
        return aSongNumber.lowercased(with: NSLocale.current)
    }
    
    class func songNumberForHarmonyURLFromNumber(_ aSongNumber: String) -> String? {
        let number: Int? = {
            if let noLetters = Int(aSongNumber) {
                return noLetters
            } else {
                let removeLetter = String(aSongNumber.dropLast())
                return Int(removeLetter)
            }
        }()
        
        if let number = number {
            if number < 10 {
                if aSongNumber.count == 1 {
                    return "00\(number)"
                } else if aSongNumber.count == 2 {
                    return "00\(number)\((aSongNumber as NSString).substring(from: 1))"
                }
            } else if number < 100 {
                if aSongNumber.count == 2 {
                    return "0\(number)"
                } else if aSongNumber.count == 3 {
                    return "0\(number)\((aSongNumber as NSString).substring(from: 2))"
                }
            }
            return aSongNumber
        }
        return nil
    }
    
    open class func defaultFilename(forTuneInfo tuneInfo: SongCollectionTuneInfo, song: Song) -> String? {
        var filename = tuneInfo.filenameFormat
            
        if filename.contains("{number}") {
            filename = filename.replacingOccurrences(of: "{number}", with: song.number.lowercased())
        }
        
        if
            let tuneWithoutMeter = song.tune?.nameWithoutMeter,
            filename.contains("{info_tune_wo_meter}")
        {
            filename = filename.replacingOccurrences(of: "{info_tune_wo_meter}", with: tuneWithoutMeter.lowercased())
        }
        
        return filename
    }
    
    open class func filename(forTuneInfo tuneInfo: SongCollectionTuneInfo, song: Song) -> String? {
        return self.defaultFilename(forTuneInfo: tuneInfo, song: song)
    }

    open class func loadTunes(forSong aSong: Song, completion: @escaping (Bool, [TuneDescription], Error?) -> Void) {
        var tuneDescriptions: [TuneDescription] = []
        if let app = UIApplication.shared.delegate as? SFWAppDelegate {
            let mainDirectory = app.appConfig.directory
            
            for tuneInfo in aSong.collection.tuneInfos {
                if let filename = Self.filename(forTuneInfo: tuneInfo, song: aSong) {
                    let subDirectory = "\(mainDirectory)/\(tuneInfo.directory)"
                    let filePath = Bundle.main.path(forResource: filename, ofType: tuneInfo.filetype, inDirectory: subDirectory)
                    
                    if let filePath = filePath {
                        let fileUrl = URL(fileURLWithPath: filePath)                        
                        let desc = LocalFileTuneDescription(length: nil, title: tuneInfo.title, composer: nil, copyright: nil, url: fileUrl, mediaType: .midi)
                        tuneDescriptions.append(desc)
                    } else {
                        print("Tunes file not found: \(filename)")
                    }
                }
            }
        }
        
        if SKCloudServiceController.authorizationStatus() == .authorized {
            let controller = SKCloudServiceController()
            
            completion(false, tuneDescriptions, nil)
            
            controller.requestCapabilities { capabilities, error in
                if let error = error {
                    completion(true, tuneDescriptions, error)
                } else {
                    if capabilities.contains(.musicCatalogPlayback) {
                        AppleMusicController.search(forSong: aSong) { (items, error) in
                            if let items = items {
                                for item in items {
                                    let desc = AppleMusicItemTuneDescription(appleMusicID: item.id, length: nil, title: item.name, composer: nil, copyright: nil)
                                    tuneDescriptions.append(desc)
                                }
                            }
                            completion(true, tuneDescriptions, nil)
                        }
                    }
                }
            }
        } else {
            completion(true, tuneDescriptions, nil)
        }
    }
    
}
