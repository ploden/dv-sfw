//
//  SheetMusicCVCell.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 11/25/19.
//  Copyright © 2019 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit
import PDFKit

class SheetMusicCVCell: UICollectionViewCell {
    @IBOutlet weak var pdfPageView: PDFPageView?
    
    func configure(withPageNumber pageNumber: Int, pdf: CGPDFDocument, allSongs: [Song], pdfRenderingConfigs: [PDFRenderingConfig], queue: OperationQueue) {
        let pdfPageNum = PDFPageView.pdfPageNumber(forPageNumber: pageNumber, allSongs: allSongs)
        pdfPageView?.pdf = pdf
        pdfPageView?.pdfRenderingConfigs = pdfRenderingConfigs
        pdfPageView?.configure(pdfPageNum, queue: queue)
    }
}
