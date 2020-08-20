//
//  RootVC.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 2/3/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

class RootVC: UIViewController {
    var sheetMusicVC: SheetMusicVC_iPhone?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if
            let sheetMusicVC = sheetMusicVC,
            sheetMusicVC.presentingViewController == nil
        {
            present(sheetMusicVC, animated: true, completion: nil)
        }
    }
}
