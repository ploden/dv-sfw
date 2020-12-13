//
//  PDFPageView.m
//  justipad
//
//  Created by PHILIP LODEN on 10/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

import UIKit
import QuartzCore

private var kPortraitScale: CGFloat = 1.50
private var kPortraitTranslateX: CGFloat = -130.0
private var kPortraitTranslateY: CGFloat = -160.0
private var kLandscapeScale: CGFloat = 1.105
private var kLandscapeTranslateX: CGFloat = -35.0
private var kLandscapeTranslateY: CGFloat = -35.0
private var k12InchPortraitScale: CGFloat = 2.05
private var k12InchPortraitTranslateXRight: CGFloat = -270.0 // negative moves left
private var k12InchPortraitTranslateXLeft: CGFloat = -259.0
private var k12InchPortraitTranslateY: CGFloat = -336.0
private var k12InchLandscapeScale: CGFloat = 1.50
private var k12InchLandscapeTranslateXRight: CGFloat = -170.0
private var k12InchLandscapeTranslateXLeft: CGFloat = -166.0
private var k12InchLandscapeTranslateY: CGFloat = -166.0 // negative moves down
private var k12Inch3rdGenPortraitScale: CGFloat = 2.05
private var k12Inch3rdGenPortraitTranslateXRight: CGFloat = -270.0 // negative moves left
private var k12Inch3rdGenPortraitTranslateXLeft: CGFloat = -259.0
private var k12Inch3rdGenPortraitTranslateY: CGFloat = -336.0
private var k12Inch3rdGenLandscapeScale: CGFloat = 1.50
private var k12Inch3rdGenLandscapeTranslateXRight: CGFloat = -170.0
private var k12Inch3rdGenLandscapeTranslateXLeft: CGFloat = -166.0
private var k12Inch3rdGenLandscapeTranslateY: CGFloat = -162.0 // negative moves down
private var k10InchPortraitScale: CGFloat = 1.66
private var k10InchPortraitTranslateXRight: CGFloat = -170.0
private var k10InchPortraitTranslateXLeft: CGFloat = -161.0
private var k10InchPortraitTranslateY: CGFloat = -212.0
private var k10InchLandscapeScale: CGFloat = 1.20
private var k10InchLandscapeTranslateXRight: CGFloat = -70.0
private var k10InchLandscapeTranslateXLeft: CGFloat = -61.0
private var k10InchLandscapeTranslateY: CGFloat = -68.0

class PDFPageView: UIView {
    var scale: CGFloat = 0.0
    var translateX: CGFloat = 0.0
    var translateY: CGFloat = 0.0
    var pdfPageNumber: Int = 0
    var pdf: CGPDFDocument!
    private var imageRef: CGImage?
    private var imageRefRect: NSValue?

    init() {
        super.init(frame: .zero)
        self.backgroundColor = .white
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configure(_ pdfPageNumber: Int) {
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
            if rect.size.height == 810.0 || rect.size.width == 810.0 {
                // ipad portrait
                currentScale = kPortraitScale
                currentTranslateY = kPortraitTranslateY
                
                if pdfPageNumber % 2 == 1 {
                    // right hand page
                    currentTranslateX = kPortraitTranslateX
                } else {
                    // left hand page
                    currentTranslateX = kPortraitTranslateX
                }
            } else if rect.size.height == 759.5 || rect.size.width == 759.5 {
                // ipad landscape
                currentScale = kLandscapeScale
                currentTranslateY = kLandscapeTranslateY
                
                if pdfPageNumber % 2 == 1 {
                    // right hand page
                    currentTranslateX = kLandscapeTranslateX
                } else {
                    // left hand page
                    currentTranslateX = kLandscapeTranslateX
                }
            } else if rect.size.height == 1302.0 || rect.size.width == 1302.0 {
                // iPad 12.9 portrait
                currentScale = k12InchPortraitScale
                currentTranslateY = k12InchPortraitTranslateY
                
                if pdfPageNumber % 2 == 1 {
                    // right hand page
                    currentTranslateX = k12InchPortraitTranslateXRight
                } else {
                    // left hand page
                    currentTranslateX = k12InchPortraitTranslateXLeft
                }
            } else if rect.size.height == 1278.0 || rect.size.width == 1278.0 {
                // iPad 12.9 3rd gen portrait
                currentScale = k12Inch3rdGenPortraitScale
                currentTranslateY = k12Inch3rdGenPortraitTranslateY
                
                if pdfPageNumber % 2 == 1 {
                    // right hand page
                    currentTranslateX = k12Inch3rdGenPortraitTranslateXRight
                } else {
                    // left hand page
                    currentTranslateX = k12Inch3rdGenPortraitTranslateXLeft
                }
            } else if rect.size.height == 960.0 || rect.size.width == 960.0 {
                // iPad 12.9 landscape
                currentScale = k12InchLandscapeScale
                currentTranslateY = k12InchLandscapeTranslateY
                
                if pdfPageNumber % 2 == 1 {
                    // right hand page
                    currentTranslateX = k12InchLandscapeTranslateXRight
                } else {
                    // left hand page
                    currentTranslateX = k12InchLandscapeTranslateXLeft
                }
            } else if rect.size.height == 1292 || rect.size.width == 990.5 {
                // iPad 12.9 3rd gen landscape
                currentScale = k12Inch3rdGenLandscapeScale
                currentTranslateY = k12Inch3rdGenLandscapeTranslateY
                
                if pdfPageNumber % 2 == 1 {
                    // right hand page
                    currentTranslateX = k12Inch3rdGenLandscapeTranslateXRight
                } else {
                    // left hand page
                    currentTranslateX = k12Inch3rdGenLandscapeTranslateXLeft
                }
            } else if rect.size.width == 834.0 {
                // iPad 10.5 portrait
                currentScale = k10InchPortraitScale
                currentTranslateY = k10InchPortraitTranslateY
                
                if pdfPageNumber % 2 == 1 {
                    // right hand page
                    currentTranslateX = k10InchPortraitTranslateXRight
                } else {
                    // left hand page
                    currentTranslateX = k10InchPortraitTranslateXLeft
                }
            } else if rect.size.width == 791.5 {
                // iPad 10.5 landscape
                currentScale = k10InchLandscapeScale
                currentTranslateY = k10InchLandscapeTranslateY
                
                if pdfPageNumber % 2 == 1 {
                    // right hand page
                    currentTranslateX = k10InchLandscapeTranslateXRight
                } else {
                    // left hand page
                    currentTranslateX = k10InchLandscapeTranslateXLeft
                }
            } else if rect.size.width == 818.5 {
                // iPad Pro 11 landscape
                currentScale = k10InchLandscapeScale
                currentTranslateY = k10InchLandscapeTranslateY
                
                if pdfPageNumber % 2 == 1 {
                    // right hand page
                    currentTranslateX = k10InchLandscapeTranslateXRight
                } else {
                    // left hand page
                    currentTranslateX = k10InchLandscapeTranslateXLeft
                }
            } else if rect.size.width == 768 {
                // iPad Pro 9.7 portrait
                currentScale = kPortraitScale
                currentTranslateY = kPortraitTranslateY
                
                if pdfPageNumber % 2 == 1 {
                    // right hand page
                    currentTranslateX = kPortraitTranslateX
                } else {
                    // left hand page
                    currentTranslateX = kPortraitTranslateX
                }
            } else if rect.size.width == 703.5 {
                // iPad Pro 9.7 landscape
                currentScale = kLandscapeScale
                currentTranslateY = kLandscapeTranslateY
                
                if pdfPageNumber % 2 == 1 {
                    // right hand page
                    currentTranslateX = kLandscapeTranslateX
                } else {
                    // left hand page
                    currentTranslateX = kLandscapeTranslateX
                }
            }  else if rect.size.width == 804.5 {
                // iPad Air 4th gen landscape
                currentScale = kLandscapeScale
                currentTranslateY = kLandscapeTranslateY
                
                if pdfPageNumber % 2 == 1 {
                    // right hand page
                    currentTranslateX = kLandscapeTranslateX
                } else {
                    // left hand page
                    currentTranslateX = kLandscapeTranslateX
                }
            } else if rect.size.width == 820.0 {
                // iPad Air 4th gen portrait
                currentScale = k10InchPortraitScale
                currentTranslateY = k10InchPortraitTranslateY
                
                if pdfPageNumber % 2 == 1 {
                    // right hand page
                    currentTranslateX = k10InchPortraitTranslateXRight
                } else {
                    // left hand page
                    currentTranslateX = k10InchPortraitTranslateXLeft
                }
            } else {
                assert(false, "PDFPageView: drawRect: insufficient info to draw page")
                return
            }
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
            
            PDFPageView.drawPageWithRect(drawnRect, currentScale: currentScale, currentTranslateX: currentTranslateX, currentTranslateY: currentTranslateY, pdf: pdf, pdfPageNumber: pdfPageNumber) { [weak self] drawnImage in
                OperationQueue.main.addOperation({
                    if let self = self {
                        self.imageRef = drawnImage
                        self.imageRefRect = NSValue(cgRect: drawnRect)
                        self.setNeedsDisplay()
                    }
                })
            }
        }
    }

    class func drawPageWithRect(_ rect: CGRect, currentScale: CGFloat, currentTranslateX: CGFloat, currentTranslateY: CGFloat, pdf: CGPDFDocument, pdfPageNumber: Int, completion: @escaping (CGImage?) -> Void) {
        OperationQueue.main.addOperation {
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
                    }
                }
                completion(image)
            }
        }
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
}
