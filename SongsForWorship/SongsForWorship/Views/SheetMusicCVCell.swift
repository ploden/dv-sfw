//
//  SheetMusicCVCell.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 11/25/19.
//  Copyright © 2019 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

class SheetMusicCVCell: UICollectionViewCell {
    @IBOutlet weak var pdfPageView: PDFPageView?
    
    func configureWithPageNumber(_ pageNumber: Int, allSongs: [Song], songsManager: SongsManager) {
        let pdfPageNum = PDFPageView.pdfPageNumber(forPageNumber: pageNumber, allSongs: allSongs)
        pdfPageView?.pdf = songsManager.currentCollection?.pdf
        pdfPageView?.configure(pdfPageNum)
    }
}
