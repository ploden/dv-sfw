//
//  ScrollingSheetMusicCVCell.swift
//  SongsForWorship
//
//  Created by Philip Loden on 4/2/21.
//  Copyright © 2021 Deo Volente, LLC. All rights reserved.
//

import UIKit

class ScrollingSheetMusicCVCell: UICollectionViewCell {
    @IBOutlet weak var pdfPageView: PDFPageView?
    @IBOutlet weak var pdfPageViewHeightConstraint: NSLayoutConstraint?
    
    func configureWithPageNumber(_ pageNumber: Int, pdf: CGPDFDocument, allSongs: [Song], songsManager: SongsManager, queue: OperationQueue, height: CGFloat) {
        if
            let pdfPageViewHeightConstraint = pdfPageViewHeightConstraint,
            pdfPageViewHeightConstraint.constant != height
        {
            pdfPageViewHeightConstraint.constant = height
        }
        let pdfPageNum = PDFPageView.pdfPageNumber(forPageNumber: pageNumber, allSongs: allSongs)
        pdfPageView?.pdf = pdf
        pdfPageView?.configure(pdfPageNum, queue: queue)
    }
}
