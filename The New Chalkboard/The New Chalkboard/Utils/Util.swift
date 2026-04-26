//
//  Util.swift
//  The New Chalkboard
//
//  Created by Israel Manzo on 2/18/24.
//

import SwiftUI
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

extension UIScreen {
    static let screenWidth = UIScreen.main.bounds.width
}

extension String {
    func getSize() -> CGFloat {
        let font = UIFont.systemFont(ofSize: 16)
        let attributes = [NSAttributedString.Key.font: font]
        let size = (self as NSString).size(withAttributes: attributes)
        return size.width
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255.0,
                  green: Double((hex >> 8) & 0xFF) / 255.0,
                  blue: Double(hex & 0xFF) / 255.0,
                  opacity: alpha)
    }

    // Sage & Slate palette (light mode).
    static let sageSlateDark = Color(hex: 0x3D5A5A)
    static let sageSlate = Color(hex: 0x5C8A8A)
    static let sage = Color(hex: 0xA8C5B5)
    static let sageSlateOffWhite = Color(hex: 0xF2F7F5)

    // App semantic colors (dynamic for dark mode).
    static let appBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? .systemBackground : UIColor(hex: 0xF2F7F5)
    })

    static let appSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? .secondarySystemBackground : UIColor(hex: 0xF2F7F5)
    })

    static let appElevatedSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? .tertiarySystemBackground : UIColor(hex: 0xA8C5B5, alpha: 0.22)
    })

    static let appTextPrimary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? .label : UIColor(hex: 0x3D5A5A)
    })

    static let appTextSecondary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? .secondaryLabel : UIColor(hex: 0x5C8A8A, alpha: 0.95)
    })

    static let appAccent = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? .systemTeal : UIColor(hex: 0x5C8A8A)
    })

    static let appBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? .separator : UIColor(hex: 0x5C8A8A, alpha: 0.25)
    })
}


