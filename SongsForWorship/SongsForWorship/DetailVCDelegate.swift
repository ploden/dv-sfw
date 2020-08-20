//
//  DetailVCDelegate.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 12/31/19.
//  Copyright © 2019 Deo Volente, LLC. All rights reserved.
//

import Foundation

protocol DetailVCDelegate: class {
    func songsToDisplayForDetailVC(_ detailVC: DetailVC?) -> [Song]?
    func isSearchingForDetailVC(_ detailVC: DetailVC?) -> Bool
}
