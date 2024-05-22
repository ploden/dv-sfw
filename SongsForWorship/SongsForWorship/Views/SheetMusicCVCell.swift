//
//  SheetMusicCVCell.swift
//  SongsForWorship
//
//  Created by Phil Loden on 11/25/19. Licensed under the MIT license, as follows:
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import UIKit
import PDFKit

typealias PageNumbers = (firstPage: Int, secondPage: Int?)

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
