//
//  TunesLoader.m
//  PsalmsForWorship
//
//  Created by PHILIP LODEN on 4/30/10.
//  Copyright 2010 Deo Volente, LLC. All rights reserved.
//

import UIKit
import AVFoundation

class TunesLoader {

    class func loadTunesForPsalm(_ aSong: Song, completion: @escaping (Error?, [TuneDescription]) -> Void) {
        var tuneDescriptions: [TuneDescription] = []
                
        if
            let currentlyLoadingPsalmNumber = aSong.number,
            let harmonyPsalmNum = TunesLoader.songNumberForHarmonyURLFromNumber(currentlyLoadingPsalmNumber)
        {
            let harmonyFilename = "\(harmonyPsalmNum).1"
            
            if let harmonyFilePath = Bundle.main.path(forResource: harmonyFilename, ofType: "mid", inDirectory: "tune_midis") {
                let desc = TuneDescription(length: nil, title: "Harmony", url: URL.init(fileURLWithPath: harmonyFilePath))
                tuneDescriptions.append(desc)
            }
            
            let partsPsalmNum = TunesLoader.songNumberForPartsURLFromNumber(currentlyLoadingPsalmNumber)
            
            for name in ["a", "b", "s", "t"] {
                let filename = "psalm_\(partsPsalmNum)_\(name)_part"
                let filePath = Bundle.main.path(forResource: filename, ofType: "mid", inDirectory: "parts_midis")
                
                if
                    let filePath = filePath,
                    let title = TunesVC.titleFromPartAbbreviation(name)
                {
                    let desc = TuneDescription(length: nil, title: title, url: URL.init(fileURLWithPath: filePath))
                    tuneDescriptions.append(desc)
                }
            }
        }
        
        completion(nil, tuneDescriptions)
    }
    
    class func loadTunes(forPsalm aSong: Song, collection: SongCollection, completion: @escaping (Error?, [TuneDescription]) -> Void) {
        var tuneDescriptions: [TuneDescription] = []
              
        if
            let app = UIApplication.shared.delegate as? PsalterAppDelegate,
            let mainDirectory = app.getAppConfig()["Directory"] as? String,
            let currentlyLoadingPsalmNumber = aSong.number
        {
            for tuneInfo in collection.tuneInfos {
                var filename = tuneInfo.filenameFormat
                    
                if filename.contains("{number}") {
                    filename = filename.replacingOccurrences(of: "{number}", with: currentlyLoadingPsalmNumber.lowercased())
                }
                
                if
                    let tuneWithoutMeter = aSong.tuneWithoutMeter,
                    filename.contains("{info_tune_wo_meter}")
                {
                    filename = filename.replacingOccurrences(of: "{info_tune_wo_meter}", with: tuneWithoutMeter.lowercased())
                }

                let subDirectory = "\(mainDirectory)/\(tuneInfo.directory)"
                let filePath = Bundle.main.path(forResource: filename, ofType: tuneInfo.fileType, inDirectory: subDirectory)
                
                if let filePath = filePath {
                    let fileUrl = URL(fileURLWithPath: filePath)
                    let desc = TuneDescription(length: nil, title: tuneInfo.title, url: fileUrl)
                    tuneDescriptions.append(desc)
                }
            }
        }
        
        completion(nil, tuneDescriptions)
    }
    
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
}
