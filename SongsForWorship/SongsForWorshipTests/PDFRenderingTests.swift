//
//  PDFRenderingTests.swift
//  SongsForWorshipTests
//
//  Created by Phil Loden on 1/5/21.
//  Copyright © 2021 Deo Volente, LLC. All rights reserved.
//

import XCTest

class PDFRenderingTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPDFRendering() throws {

    }

}
