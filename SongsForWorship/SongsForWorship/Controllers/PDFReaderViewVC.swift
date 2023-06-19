//
//  PDFReaderViewVC.swift
//  SongsForWorship
//
//  Created by Philip Loden on 4/26/23.
//  Copyright © 2023 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit
import SwiftTheme
import PDFKit

class PDFReaderViewVC: UIViewController, HasFileInfo {
    var fileInfo: FileInfo?
    @IBOutlet weak private var pdfView: PDFView?
    var fileURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pdfView = PDFView()

        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.autoScales = true
        view.addSubview(pdfView)

        pdfView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        pdfView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        pdfView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        if
            let fileInfo = fileInfo,
            fileInfo.1 == "pdf",
            let path = Bundle.main.path(forResource: fileInfo.0, ofType: fileInfo.1, inDirectory: fileInfo.2)
        {
            let url = URL(fileURLWithPath: path)
            
            if let document = PDFDocument(url: url) {
                pdfView.document = document
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if let theme = ThemeSetting(rawValue: ThemeManager.currentThemeIndex) {
            switch theme {
            case .defaultLight, .night:
                return .lightContent
            case .white:
                return .darkContent
            }
        }
        return .lightContent
    }
        
}
