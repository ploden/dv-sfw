//
//  PDFPageView.m
//  justipad
//
//  Created by Phil Loden on 10/9/10. Licensed under the MIT license, as follows:
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
                let drawnImage = PDFPageView.drawPage(
                    withRect: drawnRect,
                    currentScaleXY: currentScaleXY,
                    pdf: self.pdf,
                    pdfPageNumber: self.pdfPageNumber,
                    darkMode: darkMode
                )

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

    class func drawPage(withRect rect: CGRect,
                        currentScaleXY: ScaleXY?,
                        pdf: CGPDFDocument,
                        pdfPageNumber: Int,
                        darkMode: Bool) -> CGImage?
    {
        var image: CGImage?

        autoreleasepool {
            if let pageRef = pdf.page(at: pdfPageNumber) {
                let colorSpace = CGColorSpaceCreateDeviceGray()

                let screenScale = UIScreen.main.scale

                let screenScaledWidth: CGFloat = rect.size.width * screenScale
                let screenScaledHeight: CGFloat = rect.size.height * screenScale

                let context = CGContext(data: nil,
                                        width: Int(screenScaledWidth),
                                        height: Int(screenScaledHeight),
                                        bitsPerComponent: 8,
                                        bytesPerRow: 0,
                                        space: colorSpace,
                                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)

                if let context = context {
                    if let currentScaleXY = currentScaleXY {
                        context.translateBy(x: 0.0, y: screenScaledHeight)

                        context.scaleBy(x: 1.0, y: -1.0)

                        context.saveGState()

                        context.scaleBy(x: currentScaleXY.scale * screenScale, y: currentScaleXY.scale * screenScale)

                        let drawingTransform = pageRef.getDrawingTransform(CGPDFBox.cropBox, rect: rect, rotate: 0, preserveAspectRatio: true)

                        let translateTransform = drawingTransform.translatedBy(x: currentScaleXY.xCoordinate, y: currentScaleXY.yCoordinate)

                        context.concatenate(translateTransform)

                        context.drawPDFPage(pageRef)
                    } else {
                        let drawSize = rect.size

                        let scale = UIScreen.main.scale
                        context.scaleBy(x: scale, y: -scale)

                        // get the rectangle of the cropped inside
                        let mediaRect = pageRef.getBoxRect(CGPDFBox.trimBox)

                        context.translateBy(x: 0, y: -drawSize.height)

                        let xScale = drawSize.width / mediaRect.size.width

                        let scaleToApply: CGFloat = {
                            let yScale = drawSize.height / mediaRect.size.height
                            return xScale < yScale ? xScale : yScale
                        }()

                        context.scaleBy(x: scaleToApply, y: scaleToApply)

                        let translateX = (drawSize.width - (scaleToApply * mediaRect.size.width))
                        let translateY = (drawSize.height - (scaleToApply * mediaRect.size.height))

                        context.translateBy(x: (translateX / 2.0) / scaleToApply, y: (translateY / 2.0) / scaleToApply)

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

    class func calculateScaleXY(forRect rect: CGRect,
                                orientation: UIDeviceOrientation,
                                pageOrientation: PDFPageOrientation,
                                pdfRenderingConfig: [PDFRenderingConfig],
                                returnClosest: Bool) -> ScaleXY? {
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

        let matchingDeviceOrientationAndPageOrientation = pdfRenderingConfig.filter {
            $0.deviceOrientation == renderingDeviceOrientation && $0.pageOrientation == pageOrientation
        }

        let first: PDFRenderingConfig? = {
            if let matchingBoth = matchingDeviceOrientationAndPageOrientation.first(where: { $0.screenWidth == rect.width && $0.screenHeight == rect.height }) {
                return matchingBoth
            } else {
                return matchingDeviceOrientationAndPageOrientation.first { $0.screenWidth == rect.width || $0.screenHeight == rect.height }
            }
        }()

        if let first = first {
            var scale = first.scale as NSNumber
            var translateX = first.translateX as NSNumber
            var translateY = first.translateY as NSNumber

            if "abc".count == 0 { scale = NSNumber(value: 0); translateX = NSNumber(value: 0); translateY = NSNumber(value: 0) } // add breakpoint here to modify s, x, y expr s=newval
            print("s: \(scale) x:\(translateX) y:\(translateY)")
            return ScaleXY(scale: CGFloat(scale.floatValue), xCoordinate: CGFloat(translateX.floatValue), yCoordinate: CGFloat(translateY.floatValue))
        } else if returnClosest {
            let closest = pdfRenderingConfig.min { first, second in
                if
                    let screenWidthA = first.screenWidth,
                    let screenWidthB = second.screenWidth
                {
                    return abs(rect.width - abs(screenWidthA)) < abs(rect.width - abs(screenWidthB))
                } else {
                    return false
                }
            }

            if
                let scale = closest?.scale,
                let translateX = closest?.translateX,
                let translateY = closest?.translateY
            {
                return ScaleXY(scale: scale, xCoordinate: translateX, yCoordinate: translateY)
            }

            return ScaleXY(scale: 0.0, xCoordinate: 0.0, yCoordinate: 0.0)
        } else {
            return nil
        }
    }

}
