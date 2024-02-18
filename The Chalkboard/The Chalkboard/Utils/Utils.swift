//
//  Utils.swift
//  The Chalkboard
//
//  Created by Israel Manzo on 3/11/23.
//

import UIKit

extension UIColor {
    static var greenColor = UIColor(red: 77/255, green: 125/255, blue: 90/255, alpha: 1)
}

extension UITextField {
    func makeFontDynamic() {
        let customFont = UIFont.preferredFont(forTextStyle: .title3).pointSize
        font = UIFont(name: "GillSans-Italic", size: customFont)
        adjustsFontSizeToFitWidth = true
    }
    
    func makePlaeceholderDynamic(string: String) {
        let customFont = UIFont.preferredFont(forTextStyle: .title3).pointSize
        attributedPlaceholder = NSAttributedString(string: string, attributes: [NSAttributedString.Key.font: UIFont(name: "GillSans-Italic", size: customFont)!])
        adjustsFontForContentSizeCategory = true
        adjustsFontSizeToFitWidth = true
        isAccessibilityElement = true
    }
}

extension UILabel {
    func makeFontDynamic() {
        let customFont = UIFont.preferredFont(forTextStyle: .title3).pointSize
        font = UIFont(name: "GillSans-Italic", size: customFont)
        adjustsFontSizeToFitWidth = true
    }
}
