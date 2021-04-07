//
//  DetailVCDelegate.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 12/31/19.
//  Copyright © 2019 Deo Volente, LLC. All rights reserved.
//

import Foundation

protocol SongDetailVCDelegate: class {
    func songsToDisplayForDetailVC(_ detailVC: SongDetailVC?) -> [Song]?
    func isSearchingForDetailVC(_ detailVC: SongDetailVC?) -> Bool
}
