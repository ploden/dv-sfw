//
//  SheetMusicVC_iPhone.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 6/20/14.
//  Copyright (c) 2014 Deo Volente, LLC. All rights reserved.
//

import UIKit

class SheetMusicVC_iPhone: UIViewController, UIScrollViewDelegate {
    var songsManager: SongsManager?
    var queue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Render pdf queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    var orientation: UIDeviceOrientation = .landscapeLeft
    override class var storyboardName: String {
        get {
            return "SongDetail"
        }
    }
    @IBOutlet weak var scrollView: UIScrollView? {
        didSet {
            scrollView?.showsVerticalScrollIndicator = false
            scrollView?.showsHorizontalScrollIndicator = false
            scrollView?.isPagingEnabled = true
            scrollView?.bounces = false
            scrollView?.contentInsetAdjustmentBehavior = .never
            scrollView?.backgroundColor = .systemBackground
        }
    }
    var song: Song? {
        didSet {
            if let song = song {
                configure(with: song)
            }
        }
    }
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        if let song = song {
            configure(with: song)
        }
    }

    // MARK: - Helper methods
    func configure(with song: Song) {
        guard isViewLoaded else {
            return
        }
        
        let screenHeight = min(UIScreen.main.bounds.size.height, UIScreen.main.bounds.size.width)
        let screenWidth = max(UIScreen.main.bounds.size.height, UIScreen.main.bounds.size.width)
        
        scrollView?.subviews.forEach { $0.removeFromSuperview() }
        
        var containerViewHeight: CGFloat
        
        if screenWidth == 568.0 {
            // iPhone 5
            containerViewHeight = 938.0
        } else if screenWidth == 480.0 {
            // iPhone < 5
            containerViewHeight = 788.0
        } else if screenWidth == 667 {
            // iPhone 6
            containerViewHeight = 1070.0
        } else if screenWidth == 736 {
            // iPhone 6 Plus
            containerViewHeight = 1176.0
        } else if screenWidth == 926 {
            // iPhone 12 Pro Max
            containerViewHeight = 1246.0
        } else {
            // iPhone X
            containerViewHeight = 1246.0
        }
        
        for counter in 0..<song.pdfPageNumbers.count {
            let scrollingContainerView = UIScrollView(frame: CGRect(x: screenWidth * CGFloat(counter), y: 0, width: screenWidth, height: screenHeight))
            scrollingContainerView.showsHorizontalScrollIndicator = false
            scrollingContainerView.showsVerticalScrollIndicator = false
            scrollingContainerView.isPagingEnabled = false
            scrollingContainerView.alwaysBounceHorizontal = false
            scrollingContainerView.bounces = true
            
            if counter < song.pdfPageNumbers.count {
                let pageNumber = song.pdfPageNumbers[counter]

                let containerView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: containerViewHeight))
                
                let aView = PDFPageView()
                aView.pdf = song.collection.pdf
                
                // Position the view differently for different pages.
                if pageNumber % 2 == 1 {
                    // Right
                    if screenWidth == 568.0 {
                        // iPhone 5
                        aView.scale = 1.48
                        aView.translateX = -97
                        aView.translateY = -155
                    } else if screenWidth == 480.0 {
                        // iPhone < 5
                        aView.scale = 1.25
                        aView.translateX = -53
                        aView.translateY = -82
                    } else if screenWidth == 667 {
                        // iPhone 6, 7, 8
                        aView.scale = 1.72
                        aView.translateX = -144
                        aView.translateY = -224
                    } else if screenWidth == 736 {
                        // iPhone 6, 7, 8 Plus
                        aView.scale = 1.88
                        aView.translateX = -178
                        aView.translateY = -280
                    } else if screenWidth == 896 {
                        // iPhone Xs Max
                        aView.scale = 2
                        if orientation == .landscapeLeft {
                            aView.translateX = -222
                        } else {
                            aView.translateX = -235
                        }
                        aView.translateY = -312
                    } else if screenWidth == 926 {
                        // iPhone 12 Pro Max
                        aView.scale = 2
                        if orientation == .landscapeLeft {
                            // smaller moves left
                            aView.translateX = -230
                        } else {
                            // smaller moves left
                            aView.translateX = -245
                        }
                        aView.translateY = -312
                    } else {
                        // iPhone X
                        aView.scale = 2
                        if orientation == .landscapeLeft {
                            aView.translateX = -200
                        } else {
                            aView.translateX = -216
                        }
                        aView.translateY = -312
                    }
                } else {
                    // Left
                    if screenWidth == 568.0 {
                        // iPhone 5
                        aView.scale = 1.47
                        aView.translateX = -86
                        aView.translateY = -152
                    } else if screenWidth == 480.0 {
                        // iPhone < 5
                        aView.scale = 1.25
                        aView.translateX = -43.0
                        aView.translateY = -82.0
                    } else if screenWidth == 667 {
                        // iPhone 6
                        aView.scale = 1.72
                        aView.translateX = -135
                        aView.translateY = -224
                    } else if screenWidth == 736 {
                        // iPhone 6 Plus
                        aView.scale = 1.88
                        aView.translateX = -168
                        aView.translateY = -280
                    } else if screenWidth == 896 {
                        // iPhone Xs Max
                        aView.scale = 2
                        if orientation == .landscapeLeft {
                            aView.translateX = -215
                        } else {
                            aView.translateX = -230
                        }
                        aView.translateY = -312
                    } else if screenWidth == 926 {
                        // iPhone 12 Pro Max
                        aView.scale = 2
                        if orientation == .landscapeLeft {
                            aView.translateX = -222
                        } else {
                            aView.translateX = -236
                        }
                        aView.translateY = -312
                    } else {
                        // iPhone X
                        aView.scale = 2
                        if orientation == .landscapeLeft {
                            aView.translateX = -192
                        } else {
                            aView.translateX = -206
                        }
                        aView.translateY = -312
                    }
                }
                
                aView.configure(pageNumber, queue: queue)
                
                aView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: containerViewHeight)
                containerView.addSubview(aView)
                scrollingContainerView.addSubview(containerView)
                scrollView?.addSubview(scrollingContainerView)
                scrollingContainerView.contentSize = CGSize(width: screenWidth, height: containerViewHeight)
                scrollView?.contentSize = CGSize(width: screenWidth * CGFloat((counter + 1)), height: screenHeight)
            }
        }
    }
    
    // MARK: - UIScrollViewDelegate
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.subviews.count > 1 {
            var toChange: UIScrollView?
            
            if scrollView.contentOffset.x > 0.0 {
                toChange = scrollView.subviews[0] as? UIScrollView
            } else {
                toChange = scrollView.subviews[1] as? UIScrollView
            }
            
            toChange?.contentOffset = CGPoint.zero
        }
    }
}
