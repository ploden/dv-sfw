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
                let colorSpace = CGColorSpaceCreateDeviceGray()
                
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
                        let y = (drawSize.height - (scaleToApply * mediaRect.size.height))

                        context.translateBy(x: (x / 2.0) / scaleToApply, y: (y / 2.0) / scaleToApply)
                        
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
            if let matchingBoth = matchingDeviceOrientationAndPageOrientation.first(where: { $0.screenWidth == rect.width && $0.screenHeight == rect.height }) {
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
