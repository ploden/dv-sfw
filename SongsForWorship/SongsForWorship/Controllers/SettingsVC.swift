//
//  SettingsTableVC.swift
//  SongsForWorship
//
//  Created by Philip Loden on 9/12/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

class SettingsVC: UIViewController {
    @IBOutlet var viewsToMakeCircles: [UIView]?
    @IBOutlet weak var systemFontCheckMarkImageView: UIImageView?
    @IBOutlet weak var customFontCheckMarkImageView: UIImageView?
    @IBOutlet weak var increaseFontSizeButton: UIButton?
    @IBOutlet weak var decreaseFontSizeButton: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureThemeViews()
        
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
            settings.theme.rawValue < viewsToMakeCircles.count
        {
            let sorted = viewsToMakeCircles.sorted { $0.superview!.frame.origin.x < $1.superview!.frame.origin.x }
            sorted[settings.theme.rawValue].layer.borderWidth = 2.0
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
        
    @IBAction func switchValueChanged(sender: Any) {
        if let aSwitch = sender as? UISwitch {
            if let settings = Settings(fromUserDefaults: .standard) {
                _ = settings.new(withShouldUseSystemFonts: aSwitch.isOn).save(toUserDefaults: .standard)
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
            _ = settings.new(withTheme: .defaultLight).save(toUserDefaults: .standard)
            configureThemeViews()
        }
    }

    @IBAction func whiteThemeTapped(_ sender: Any) {
        if let settings = Settings(fromUserDefaults: UserDefaults.standard) {
            _ = settings.new(withTheme: .white).save(toUserDefaults: .standard)
            configureThemeViews()
        }
    }
    
    @IBAction func darkThemeTapped(_ sender: Any) {
        if let settings = Settings(fromUserDefaults: UserDefaults.standard) {
            _ = settings.new(withTheme: .night).save(toUserDefaults: .standard)
            configureThemeViews()
        }
    }
    
}
