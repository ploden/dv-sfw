//
//  FlowLayout.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 8/2/17.
//  Copyright © 2017 Deo Volente, LLC. All rights reserved.
//

import UIKit

class FlowLayout: UICollectionViewFlowLayout {
    private var currentSize = CGSize.zero
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        scrollDirection = UICollectionView.ScrollDirection.horizontal
        currentSize = CGSize.zero        
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if newBounds.size.equalTo(currentSize) == false {
            currentSize = newBounds.size
            invalidateLayout()
            return false
        } else {
            return false
        }
    }
}
