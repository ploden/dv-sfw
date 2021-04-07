//
//  PDFPageView.m
//  justipad
//
//  Created by PHILIP LODEN on 10/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

import UIKit
import QuartzCore
import Accelerate
import simd
import PDFKit

enum PDFPageOrientation {
    case left, right
}

class PDFPageView: UIView {
    var queue: OperationQueue?
    var scale: CGFloat = 0.0
    var translateX: CGFloat = 0.0
    var translateY: CGFloat = 0.0
    var pdfPageNumber: Int = 0
    var pdf: CGPDFDocument!
    var pdfRenderingConfigs: [PDFRenderingConfig]?
    private var imageRef: CGImage?
    private var imageRefRect: NSValue?
    
    init() {
        super.init(frame: .zero)
        self.backgroundColor = .systemBackground
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configure(_ pdfPageNumber: Int, queue: OperationQueue) {
        self.queue = queue
        self.pdfPageNumber = pdfPageNumber
        imageRef = nil
        imageRefRect = nil
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let currentScaleXY: ScaleXY? = {
            if UIDevice.current.userInterfaceIdiom == .pad {
                // draw based on size of the view
                return nil
            } else if let pdfRenderingConfigs = self.pdfRenderingConfigs {
                let pageOrientation = pdfPageNumber % 2 == 1 ? PDFPageOrientation.right : PDFPageOrientation.left
                return PDFPageView.calculateScaleXY(forRect: rect,
                                                    orientation: UIDevice.current.orientation,
                                                    pageOrientation: pageOrientation,
                                                    pdfRenderingConfig: pdfRenderingConfigs,
                                                    returnClosest: false)
            } else {
                // draw based on size of the view
                return nil
            }
        }()
        
        if
            let imageRef = imageRef,
            let imageRefRect = imageRefRect,
            imageRefRect.cgRectValue.equalTo(rect)
        {
            let context = UIGraphicsGetCurrentContext()
            context?.saveGState()
            context?.draw(imageRef, in: rect)
            context?.restoreGState()
        } else {
            let drawnRect = rect
            let darkMode = self.traitCollection.userInterfaceStyle == .dark

            queue?.addOperation {
                let drawnImage = PDFPageView.drawPage(withRect: drawnRect, currentScaleXY: currentScaleXY, pdf: self.pdf, pdfPageNumber: self.pdfPageNumber, darkMode: darkMode)
                
                OperationQueue.main.addOperation { [weak self] in
                    if let self = self {
                        self.imageRef = drawnImage
                        self.imageRefRect = NSValue(cgRect: drawnRect)
                        self.setNeedsDisplay()
                    }
                }
            }
        }
    }
    
    class func drawPage(withRect rect: CGRect, currentScaleXY: ScaleXY?, pdf: CGPDFDocument, pdfPageNumber: Int, darkMode: Bool) -> CGImage? {
        var image: CGImage?
        
        autoreleasepool {
            if let pageRef = pdf.page(at: pdfPageNumber) {
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                
                let screenScale = UIScreen.main.scale
                
                let screenScaledWidth: CGFloat = rect.size.width * screenScale
                let screenScaledHeight: CGFloat = rect.size.height * screenScale
                
                let context = CGContext(data: nil, width: Int(screenScaledWidth), height: Int(screenScaledHeight), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
                                
                if let context = context {
                    if let currentScaleXY = currentScaleXY {
                        context.translateBy(x: 0.0, y: screenScaledHeight)
                        
                        context.scaleBy(x: 1.0, y: -1.0)
                        
                        context.saveGState()
                        
                        context.scaleBy(x: currentScaleXY.scale * screenScale, y: currentScaleXY.scale * screenScale)
                        
                        let drawingTransform = pageRef.getDrawingTransform(CGPDFBox.cropBox, rect: rect, rotate: 0, preserveAspectRatio: true)
                        
                        let translateTransform = drawingTransform.translatedBy(x: currentScaleXY.x, y: currentScaleXY.y)
                        
                        context.concatenate(translateTransform)
                        
                        context.drawPDFPage(pageRef)
                    } else {
                        let drawSize = rect.size
                        
                        let scale = UIScreen.main.scale
                        context.scaleBy(x: scale, y: -scale);
                        
                        // get the rectangle of the cropped inside
                        let mediaRect = pageRef.getBoxRect(CGPDFBox.trimBox);
                        
                        context.translateBy(x: 0, y: -drawSize.height);
                        
                        let xScale = drawSize.width / mediaRect.size.width
                        
                        let scaleToApply: CGFloat = {
                            let yScale = drawSize.height / mediaRect.size.height
                            return xScale < yScale ? xScale : yScale
                        }()
                        
                        context.scaleBy(x: scaleToApply, y: scaleToApply)
                        
                        let x = (drawSize.width - (scaleToApply * mediaRect.size.width))
                        context.translateBy(x: (x / 2.0) / scaleToApply, y: 0)
                        
                        context.drawPDFPage(pageRef)
                    }

                    image = context.makeImage()
                                                            
                    if darkMode {
                        // Create a `CIImage` from the input image.
                        let inputImage = CIImage(cgImage: image!)
                        
                        // Create an inverting filter and set its input image.
                        guard let filter = CIFilter(name: "CIColorInvert") else { return }
                        filter.setValue(inputImage, forKey: kCIInputImageKey)
                        
                        // Get the output `CIImage` from the filter.
                        guard let outputCIImage = filter.outputImage else { return }
                        
                        let context = CIContext(options: nil)
                        image = context.createCGImage(outputCIImage, from: outputCIImage.extent)
                    }
                }
            }
        }
        
        return image
    }

    class func psalm(forPdfPageNum pageNum: Int, allSongs: [AnyHashable]?) -> Song? {
        for song in allSongs ?? [] {
            guard let song = song as? Song else {
                continue
            }
            for pdfPageNum in song.pdfPageNumbers {
                if pdfPageNum == pageNum {
                    return song
                }
            }
        }
        return nil
    }

    class func pageNumberForPsalm(_ aSong: Song, allSongs: [Song], displayMode: DisplayMode) -> Int {
        if displayMode == .singlePageMetre {
            /*
            var count = 0
            
            for i in 0..<allSongs.count {
                let song = allSongs[i]
                
                if aSong == song {
                    return count
                } else {
                    count += (song.isTuneCopyrighted) ? 1 : song.pdfPageNumbers.count
                }
            }
             */
            if let firstPDFPage = aSong.pdfPageNumbers.first {
                return firstPDFPage - 1
            }
        } else if displayMode == .doublePageAsNeededPDF {
            return aSong.index
        }

        return 0
    }

    class func numberOfPages(_ allSongs: [Song]?, displayMode: DisplayMode) -> Int {
        if let allSongs = allSongs {
            if displayMode == .singlePageMetre {
                var tuneCopyrightedCount = 0
                var aSet = Set<Int>()
                for song in allSongs {
                    if song.isTuneCopyrighted {
                        tuneCopyrightedCount += 1
                    } else {
                        song.pdfPageNumbers.forEach { aSet.insert($0) }
                    }
                }
                return aSet.count + tuneCopyrightedCount
            } else if displayMode == .doublePageAsNeededPDF {
                return allSongs.map { ($0.isTuneCopyrighted) ? 1 : Int(ceil(Double($0.pdfPageNumbers.count) / 2.0)) }.reduce(0, +)
            }
        }
        return 0
    }

    class func songForPageNumber(_ pageNumber: Int, allSongs: [Song], displayMode: DisplayMode) -> Song? {
        if displayMode == .singlePageMetre {
            let adjustedPageNumber = pageNumber + 1
            return allSongs.first { $0.pdfPageNumbers.contains(adjustedPageNumber) }
        } else if displayMode == .doublePageAsNeededPDF {
            var count = 0
            
            for song in allSongs {
                count += (song.isTuneCopyrighted) ? 1 : Int(ceil(Double(song.pdfPageNumbers.count) / 2.0))
                if count > pageNumber {
                    return song
                }
            }
        }
        
        return nil
    }

    class func pdfPageNumber(forPageNumber pageNumber: Int, allSongs: [AnyHashable]?) -> Int {
        var count = 0

        for song in allSongs ?? [] {
            guard let song = song as? Song else {
                continue
            }
            if song.isTuneCopyrighted {
                count += 1
            } else {
                for i in 0..<song.pdfPageNumbers.count {
                    count += 1
                    if count > pageNumber {
                        return song.pdfPageNumbers[i]
                    }
                }
            }
        }

        return NSNotFound
    }
    
    class func calculateScaleXY(forRect rect: CGRect, orientation: UIDeviceOrientation, pageOrientation: PDFPageOrientation, pdfRenderingConfig: [PDFRenderingConfig], returnClosest: Bool) -> ScaleXY? {
        let renderingDeviceOrientation: PDFRenderingDeviceOrientation = {
            if orientation == .portrait {
                return .portrait
            } else {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    return .landscape
                } else if orientation == .landscapeLeft {
                    return .landscapeLeft
                } else if orientation == .landscapeRight {
                    return .landscapeRight
                }
            }
            return .portrait
        }()
        
        let pageOrientation: PDFRenderingPageOrientation = pageOrientation == .right ? .right : .left

        let matchingDeviceOrientationAndPageOrientation = pdfRenderingConfig.filter { $0.deviceOrientation == renderingDeviceOrientation && $0.pageOrientation == pageOrientation }
        
        let first: PDFRenderingConfig? = {
            if let matchingBoth = matchingDeviceOrientationAndPageOrientation.first { $0.screenWidth == rect.width && $0.screenHeight == rect.height } {
                return matchingBoth
            } else {
                return matchingDeviceOrientationAndPageOrientation.first { $0.screenWidth == rect.width || $0.screenHeight == rect.height }
            }
        }()
        
        if let first = first {
            var s = first.scale as NSNumber
            var x = first.translateX as NSNumber
            var y = first.translateY as NSNumber
            
            if "abc".count == 0 { s = NSNumber(value: 0); x = NSNumber(value: 0); y = NSNumber(value: 0) } // add breakpoint here to modify s, x, y expr s=newval
            print("s: \(s) x:\(x) y:\(y)")
            return ScaleXY(scale: CGFloat(s.floatValue), x: CGFloat(x.floatValue), y: CGFloat(y.floatValue))
        } else if returnClosest {
            let closest = pdfRenderingConfig.min { a, b in
                if
                    let screenWidthA = a.screenWidth,
                    let screenWidthB = a.screenWidth
                {
                    return abs(rect.width - abs(screenWidthA)) < abs(rect.width - abs(screenWidthB))
                } else {
                    return false
                }
            }
            
            if
                let s = closest?.scale,
                let x = closest?.translateX,
                let y = closest?.translateY
            {
                return ScaleXY(scale: s, x: x, y: y)
            }
            
            return ScaleXY(scale: 0.0, x: 0.0, y: 0.0)
        } else {
            return nil
        }
    }
    
}
