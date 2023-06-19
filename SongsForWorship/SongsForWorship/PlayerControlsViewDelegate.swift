//
//  PlayerControlsViewDelegate.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 5/2/11.
//  Copyright 2011 Deo Volente, LLC. All rights reserved.
//

import Foundation

protocol PlayerControlsViewDelegate: AnyObject {
    func loopButtonPressed()
    func playButtonPressed()
    func prevButtonPressed()
    func nextButtonPressed()
    func playbackRateDidChange()
}
