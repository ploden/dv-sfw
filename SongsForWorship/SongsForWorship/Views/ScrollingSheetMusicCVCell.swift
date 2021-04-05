//
//  ScrollingSheetMusicCVCell.swift
//  SongsForWorship
//
//  Created by Philip Loden on 4/2/21.
//  Copyright © 2021 Deo Volente, LLC. All rights reserved.
//

import UIKit
import PDFKit

class ScrollingSheetMusicCVCell: UICollectionViewCell {
    @IBOutlet weak var pdfPageView: PDFPageView?
    @IBOutlet weak var pdfPageViewHeightConstraint: NSLayoutConstraint?
    
    func configure(withPageNumber pageNumber: Int, pdf: CGPDFDocument, allSongs: [Song], pdfRenderingConfigs: [PDFRenderingConfig], queue: OperationQueue, height: CGFloat) {
        if
            let pdfPageViewHeightConstraint = pdfPageViewHeightConstraint,
            pdfPageViewHeightConstraint.constant != height
        {
            pdfPageViewHeightConstraint.constant = height
        }
        let pdfPageNum = PDFPageView.pdfPageNumber(forPageNumber: pageNumber, allSongs: allSongs)
        pdfPageView?.pdf = pdf
        pdfPageView?.pdfRenderingConfigs = pdfRenderingConfigs
        pdfPageView?.configure(pdfPageNum, queue: queue)
    }
}
