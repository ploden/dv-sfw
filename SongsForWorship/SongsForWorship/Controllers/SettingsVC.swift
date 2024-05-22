//
//  SettingsTableVC.swift
//  SongsForWorship
//
//  Created by Phil Loden on 9/12/20. Licensed under the MIT license, as follows:
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

class SettingsVC: UIViewController {
    var appConfig: AppConfig!
    @IBOutlet var viewsToMakeCircles: [UIView]?
    @IBOutlet weak var systemFontCheckMarkImageView: UIImageView?
    @IBOutlet weak var customFontCheckMarkImageView: UIImageView?
    @IBOutlet weak var customFontLabel: UILabel?
    @IBOutlet weak var increaseFontSizeButton: UIButton?
    @IBOutlet weak var decreaseFontSizeButton: UIButton?
    @IBOutlet weak var autoNightThemeSwitch: UISwitch?

    override func viewDidLoad() {
        super.viewDidLoad()
        customFontLabel?.text = appConfig?.defaultFontDisplayName
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureThemeViews()
        configureAutoNightThemeSwitch()

        if let settings = Settings(fromUserDefaults: UserDefaults.standard) {
            customFontCheckMarkImageView?.isHidden = settings.shouldUseSystemFonts
            systemFontCheckMarkImageView?.isHidden = !settings.shouldUseSystemFonts

            increaseFontSizeButton?.isEnabled = settings.canIncreaseFontSize()
            decreaseFontSizeButton?.isEnabled = settings.canDecreaseFontSize()
        }
    }

    func configureThemeViews() {
        viewsToMakeCircles?.forEach {
            $0.layer.cornerRadius = $0.frame.width / 2.0
            $0.clipsToBounds = true
            $0.layer.borderColor = UIColor.lightGray.cgColor
            $0.layer.borderWidth = 0.5
        }

        if
            let settings = Settings(fromUserDefaults: UserDefaults.standard),
            let viewsToMakeCircles = viewsToMakeCircles,
            settings.calculateTheme(forUserInterfaceStyle: style()).rawValue < viewsToMakeCircles.count
        {
            let sorted = viewsToMakeCircles.sorted { $0.superview!.frame.origin.x < $1.superview!.frame.origin.x }
            sorted[settings.calculateTheme(forUserInterfaceStyle: style()).rawValue].layer.borderWidth = 2.0
        }
    }

    func configureAutoNightThemeSwitch() {
        if let settings = Settings(fromUserDefaults: .standard) {
            autoNightThemeSwitch?.isOn = settings.autoNightTheme
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return false
    }

    // MARK: - IBActions

    @IBAction func switchValueChanged(sender: Any) {
        if let aSwitch = sender as? UISwitch {
            if let settings = Settings(fromUserDefaults: .standard) {
                _ = settings.new(
                    withAutoNightTheme: aSwitch.isOn,
                    userInterfaceStyle: UIScreen.main.traitCollection.userInterfaceStyle
                ).save(toUserDefaults: .standard)
                configureThemeViews()
            }
        }
    }

    @IBAction func systemFontViewTapped(_ sender: Any) {
        if let settings = Settings(fromUserDefaults: UserDefaults.standard) {
            customFontCheckMarkImageView?.isHidden = true
            systemFontCheckMarkImageView?.isHidden = false
            _ = settings.new(withShouldUseSystemFonts: true).save(toUserDefaults: .standard)
        }
    }

    @IBAction func customFontViewTapped(_ sender: Any) {
        if let settings = Settings(fromUserDefaults: UserDefaults.standard) {
            customFontCheckMarkImageView?.isHidden = false
            systemFontCheckMarkImageView?.isHidden = true
            _ = settings.new(withShouldUseSystemFonts: false).save(toUserDefaults: .standard)
        }
    }

    @IBAction func increaseTextSizeTapped(_ sender: Any) {
        if let settings = Settings(fromUserDefaults: UserDefaults.standard) {
            if let updatedSettings = settings.newWithIncreasedFontSize().save(toUserDefaults: .standard) {
                increaseFontSizeButton?.isEnabled = updatedSettings.canIncreaseFontSize()
                decreaseFontSizeButton?.isEnabled = updatedSettings.canDecreaseFontSize()
            }
        }
    }

    @IBAction func decreaseTextSizeTapped(_ sender: Any) {
        if let settings = Settings(fromUserDefaults: UserDefaults.standard) {
            if let updatedSettings = settings.newWithDecreasedFontSize().save(toUserDefaults: .standard) {
                increaseFontSizeButton?.isEnabled = updatedSettings.canIncreaseFontSize()
                decreaseFontSizeButton?.isEnabled = updatedSettings.canDecreaseFontSize()
            }
        }
    }

    @IBAction func lightThemeTapped(_ sender: Any) {
        if let settings = Settings(fromUserDefaults: UserDefaults.standard) {
            _ = settings.new(withTheme: .defaultLight, userInterfaceStyle: style()).save(toUserDefaults: .standard)
            configureThemeViews()
            configureAutoNightThemeSwitch()
        }
    }

    @IBAction func whiteThemeTapped(_ sender: Any) {
        if let settings = Settings(fromUserDefaults: UserDefaults.standard) {
            _ = settings.new(withTheme: .white, userInterfaceStyle: style()).save(toUserDefaults: .standard)
            configureThemeViews()
            configureAutoNightThemeSwitch()
        }
    }

    @IBAction func darkThemeTapped(_ sender: Any) {
        if let settings = Settings(fromUserDefaults: UserDefaults.standard) {
            _ = settings.new(withTheme: .night, userInterfaceStyle: style()).save(toUserDefaults: .standard)
            configureThemeViews()
            configureAutoNightThemeSwitch()
        }
    }

    func style() -> UIUserInterfaceStyle {
        return UIScreen.main.traitCollection.userInterfaceStyle
    }
}

extension SettingsVC: HasAppConfig {}
