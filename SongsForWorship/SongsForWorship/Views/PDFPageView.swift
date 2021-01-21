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
        
        var currentScale: CGFloat
        var currentTranslateX: CGFloat
        var currentTranslateY: CGFloat
        
        // TODO: remove dependence on iPad resolutions
        if !(scale != 0.0 || translateX != 0.0 || translateY != 0.0) {
            let pageOrientation = pdfPageNumber % 2 == 1 ? PDFPageOrientation.right : PDFPageOrientation.left
            let currentScaleXY = PDFPageView.calculateScaleXY(forRect: rect, orientation: UIDevice.current.orientation, pageOrientation: pageOrientation)
            currentScale = currentScaleXY.scale
            currentTranslateX = currentScaleXY.x
            currentTranslateY = currentScaleXY.y
        } else {
            currentScale = scale
            currentTranslateX = translateX
            currentTranslateY = translateY
        }
        
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
                let drawnImage = PDFPageView.drawPage(withRect: drawnRect, currentScale: currentScale, currentTranslateX: currentTranslateX, currentTranslateY: currentTranslateY, pdf: self.pdf, pdfPageNumber: self.pdfPageNumber, darkMode: darkMode)
                
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
    
    class func drawPage(withRect rect: CGRect, currentScale: CGFloat, currentTranslateX: CGFloat, currentTranslateY: CGFloat, pdf: CGPDFDocument, pdfPageNumber: Int, darkMode: Bool) -> CGImage? {
        var image: CGImage?
        
        autoreleasepool {
            if let pageRef = pdf.page(at: pdfPageNumber) {
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                
                let screenScale = UIScreen.main.scale
                
                let screenScaledWidth: CGFloat = rect.size.width * screenScale
                let screenScaledHeight: CGFloat = rect.size.height * screenScale
                
                let context = CGContext(data: nil, width: Int(screenScaledWidth), height: Int(screenScaledHeight), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
                
                if let context = context {
                    context.translateBy(x: 0.0, y: screenScaledHeight)
                    
                    context.scaleBy(x: 1.0, y: -1.0)
                    
                    context.saveGState()
                    
                    context.scaleBy(x: currentScale * screenScale, y: currentScale * screenScale)
                    
                    let drawingTransform = pageRef.getDrawingTransform(CGPDFBox.cropBox, rect: rect, rotate: 0, preserveAspectRatio: true)
                    
                    let translateTransform = drawingTransform.translatedBy(x: currentTranslateX, y: currentTranslateY)
                    
                    context.concatenate(translateTransform)
                    
                    context.drawPDFPage(pageRef)
                    
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

    class func pageNumberForPsalm(_ aSong: Song, allSongs: [Song], idx: NSNumber?) -> Int {
        var count = 0

        for i in 0..<allSongs.count {
            let song = allSongs[i]

            if aSong == song {
                if idx != nil {
                    if i == idx?.intValue ?? 0 {
                        return count
                    }
                } else {
                    return count
                }
            } else {
                count += (song.isTuneCopyrighted) ? 1 : song.pdfPageNumbers.count
            }
        }

        return 0
    }

    class func numberOfPages(_ allSongs: [AnyHashable]?) -> Int {
        var count = 0

        for song in allSongs ?? [] {
            guard let song = song as? Song else {
                continue
            }
            count += (song.isTuneCopyrighted) ? 1 : song.pdfPageNumbers.count
        }

        return count
    }

    class func songForPageNumber(_ pageNumber: Int, allSongs: [Song]) -> Song? {
        var count = 0

        for psalm in allSongs {
            count += (psalm.isTuneCopyrighted) ? 1 : psalm.pdfPageNumbers.count
            if count > pageNumber {
                return psalm
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
    
    class func calculateScaleXY(forRect rect: CGRect, orientation: UIDeviceOrientation, pageOrientation: PDFPageOrientation) -> ScaleXY {
        let dicts: [[String:Any]]? = {
            let targetName = Bundle.main.infoDictionary?["CFBundleName"] as! String
            let dirName = targetName.lowercased() + "-resources"
            
            if let path = Bundle.main.path(forResource: "pfw_pdf_rendering", ofType: "plist", inDirectory: dirName) {
                let plistXML = FileManager.default.contents(atPath: path)!
                do {
                    let plistData = try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainers, format: .none) as! [[String:Any]]
                    return plistData
                } catch {
                    print("Error reading plist: \(error)")
                }
            }
            return nil
        }()
        
        let orientationString = orientation == .portrait ? "Portrait" : "Landscape"
        let pageOrientationString = pageOrientation == .right ? "Right" : "Left"

        let ipads = dicts?.filter { ($0["DeviceType"] as? String) == "iPad" &&
            ($0["DeviceOrientation"] as? String) == orientationString &&
            ($0["PageOrientation"] as? String) == pageOrientationString }
        
        let first = ipads?.first { $0["ScreenWidth"] as? CGFloat == rect.width || $0["ScreenHeight"] as? CGFloat == rect.height }
        
        if
            let first = first,
            var s = first["Scale"] as? NSNumber,
            var x = first["TranslateX"] as? NSNumber,
            var y = first["TranslateY"] as? NSNumber
        {
            if "abc".count == 0 { s = NSNumber(value: 0); x = NSNumber(value: 0); y = NSNumber(value: 0) }
            print("s: \(s) x:\(x) y:\(y)")
            return ScaleXY(scale: CGFloat(s.floatValue), x: CGFloat(x.floatValue), y: CGFloat(y.floatValue))
        } else if let ipads = ipads {
            let closest = ipads.min { a, b in
                if
                    let screenWidthA = a["ScreenWidth"] as? CGFloat,
                    let screenWidthB = a["ScreenWidth"] as? CGFloat
                {
                    return abs(rect.width - abs(screenWidthA)) < abs(rect.width - abs(screenWidthB))
                } else {
                    return false
                }
            }
            
            if
                let s = closest?["Scale"] as? NSNumber,
                let x = closest?["TranslateX"] as? NSNumber,
                let y = closest?["TranslateY"] as? NSNumber
            {
                return ScaleXY(scale: CGFloat(s.floatValue), x: CGFloat(x.floatValue), y: CGFloat(y.floatValue))
            }
        }
        
        return ScaleXY(scale: 0.0, x: 0.0, y: 0.0)
    }
    
}
