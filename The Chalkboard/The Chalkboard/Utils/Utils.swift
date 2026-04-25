//
//  Utils.swift
//  The Chalkboard
//
//  Created by Israel Manzo on 3/11/23.
//

import UIKit

enum ViewState<Value> {
    case idle
    case loading
    case empty
    case loaded(Value)
    case error(String)
}

extension ViewState {
    var value: Value? {
        if case let .loaded(value) = self { return value }
        return nil
    }
}

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

/// Shared auto-growing text view used across the app (main input + card detail editor).
final class AutoGrowingTextView: UITextView {
    private var lastWidth: CGFloat = 0

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }

    override var contentSize: CGSize {
        didSet {
            if oldValue != contentSize {
                invalidateIntrinsicContentSize()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width != lastWidth else { return }
        lastWidth = bounds.width
        invalidateIntrinsicContentSize()
    }
}
