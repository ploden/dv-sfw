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
    @IBOutlet weak var scrollView: UIScrollView?
    
    func configure(withPageNumber pageNumber: Int?, pdf: CGPDFDocument, allSongs: [Song], pdfRenderingConfigs: [PDFRenderingConfig]?, queue: OperationQueue) {
        //let pdfPageNum = PDFPageView.pdfPageNumber(forPageNumber: pageNumber, allSongs: allSongs)
        pdfPageView?.pdf = pdf
        pdfPageView?.pdfRenderingConfigs = pdfRenderingConfigs
        
        if let pageNumber = pageNumber {
            pdfPageView?.isHidden = false
            pdfPageView?.configure(pageNumber, queue: queue)
        } else {
            pdfPageView?.isHidden = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.scrollView?.contentOffset = .zero
    }
}
