//
//  AVMIDIPlayer.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 1/2/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation
import AVKit

extension AVMIDIPlayer {
    
    convenience init(withTune tune: TuneDescription, soundBankURL: URL) throws {
        try self.init(contentsOf: tune.url, soundBankURL: soundBankURL)
    }
    
    static func songSoundBankUrl() -> URL? {
        let targetName = Bundle.main.infoDictionary?["CFBundleName"] as! String
        let dirName = targetName.lowercased() + "-resources"
                
        if
            let app = UIApplication.shared.delegate as? PsalterAppDelegate,
            let soundFontName = app.getAppConfig()["Sound font"] as? String,
            let path = Bundle.main.path(forResource: soundFontName, ofType: "sf2", inDirectory: dirName)
        {
            return URL(fileURLWithPath: path)
        }
        
        return nil        
    }
    
    static func midiPlayer(withTune tune: TuneDescription, soundBankURL: URL) throws -> AVMIDIPlayer {
        try AVMIDIPlayer(withTune: tune, soundBankURL: soundBankURL)
    }
    
}
