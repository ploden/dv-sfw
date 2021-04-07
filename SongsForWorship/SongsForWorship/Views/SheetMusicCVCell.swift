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

typealias PageNumbers = (firstPage: Int, secondPage:  Int?)

class SheetMusicCVCell: UICollectionViewCell {
    @IBOutlet weak var singlePDFPageView: PDFPageView?
    @IBOutlet weak var firstPDFPageView: PDFPageView?
    @IBOutlet weak var secondPDFPageView: PDFPageView?

    func configure(withPDFPageNumbers pageNumbers: PageNumbers?, pdf: CGPDFDocument, allSongs: [Song], pdfRenderingConfigs: [PDFRenderingConfig]?, queue: OperationQueue) {
        if
            let singlePDFPageView = singlePDFPageView,
            let firstPDFPageView = firstPDFPageView,
            let secondPDFPageView = secondPDFPageView,
            let pageNumbers = pageNumbers
        {
            if let secondPDFPageNum = pageNumbers.secondPage {
                singlePDFPageView.isHidden = true
                firstPDFPageView.isHidden = false
                secondPDFPageView.isHidden = false
                
                let firstPDFPageNum = pageNumbers.firstPage
                firstPDFPageView.pdf = pdf
                firstPDFPageView.pdfRenderingConfigs = pdfRenderingConfigs
                firstPDFPageView.configure(firstPDFPageNum, queue: queue)
                
                secondPDFPageView.pdf = pdf
                secondPDFPageView.pdfRenderingConfigs = pdfRenderingConfigs
                secondPDFPageView.configure(secondPDFPageNum, queue: queue)
            } else {
                singlePDFPageView.isHidden = false
                firstPDFPageView.isHidden = true
                secondPDFPageView.isHidden = true
                
                let pdfPageNum = pageNumbers.firstPage
                singlePDFPageView.pdf = pdf
                singlePDFPageView.pdfRenderingConfigs = pdfRenderingConfigs
                singlePDFPageView.configure(pdfPageNum, queue: queue)
            }
        } else {
            firstPDFPageView?.isHidden = true
            secondPDFPageView?.isHidden = true
            singlePDFPageView?.isHidden = true
        }
    }
}
