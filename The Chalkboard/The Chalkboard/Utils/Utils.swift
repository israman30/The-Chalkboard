//
//  Utils.swift
//  The Chalkboard
//
//  Created by Israel Manzo on 3/11/23.
//

import UIKit

enum ViewState<Value> {
    /// No request has started yet (or the view is waiting for user input).
    case idle
    /// A request is in flight; the UI can show a spinner/skeleton.
    case loading
    /// The request succeeded but returned no content to render.
    case empty
    /// The request succeeded with data ready to render.
    case loaded(Value)
    /// A user-facing error message; keep it stringly-typed so UI can display it directly.
    case error(String)
}

extension ViewState {
    var value: Value? {
        if case let .loaded(value) = self { return value }
        return nil
    }
}

extension UIColor {
    /// Convenience for declaring design-system colors with a single hex literal.
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }

    // Sage & Slate palette (light mode).
    static let sageSlateDark = UIColor(hex: 0x3D5A5A)
    static let sageSlate = UIColor(hex: 0x5C8A8A)
    static let sage = UIColor(hex: 0xA8C5B5)
    static let sageSlateOffWhite = UIColor(hex: 0xF2F7F5)

    // App semantic colors (dynamic for dark mode).
    // These are defined as dynamic colors so the UIKit UI can stay readable across light/dark mode
    // while still using the app’s palette when available.
    static let appBackground = UIColor { trait in
        trait.userInterfaceStyle == .dark ? .systemBackground : .sageSlateOffWhite
    }

    static let appSurface = UIColor { trait in
        trait.userInterfaceStyle == .dark ? .secondarySystemBackground : .sageSlateOffWhite
    }

    static let appElevatedSurface = UIColor { trait in
        trait.userInterfaceStyle == .dark ? .tertiarySystemBackground : UIColor.sage.withAlphaComponent(0.22)
    }

    static let appTextPrimary = UIColor { trait in
        trait.userInterfaceStyle == .dark ? .label : .sageSlateDark
    }

    static let appTextSecondary = UIColor { trait in
        trait.userInterfaceStyle == .dark ? .secondaryLabel : UIColor.sageSlate.withAlphaComponent(0.95)
    }

    static let appAccent = UIColor { trait in
        trait.userInterfaceStyle == .dark ? .systemTeal : .sageSlate
    }

    static let appAccentPressed = UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.systemTeal.withAlphaComponent(0.85) : .sageSlateDark
    }

    static let appOnAccent = UIColor { _ in
        .white
    }

    static let appBorder = UIColor { trait in
        trait.userInterfaceStyle == .dark ? .separator : UIColor.sageSlate.withAlphaComponent(0.25)
    }
}

enum AppTheme {
    static func applySageAndSlate() {
        guard #available(iOS 13.0, *) else { return }

        // Centralize navigation bar styling so individual screens don’t need to repeat appearance code.
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = .appBackground
        nav.titleTextAttributes = [
            .foregroundColor: UIColor.appTextPrimary
        ]
        nav.largeTitleTextAttributes = [
            .foregroundColor: UIColor.appTextPrimary
        ]

        let bar = UINavigationBar.appearance()
        bar.standardAppearance = nav
        bar.scrollEdgeAppearance = nav
        bar.compactAppearance = nav
        bar.tintColor = .appAccent
    }
}

extension UITextField {
    func makeFontDynamic() {
        // Use the app’s font while still participating in Dynamic Type scaling.
        let customFont = UIFont.preferredFont(forTextStyle: .title3).pointSize
        font = UIFont(name: "GillSans-Italic", size: customFont)
        adjustsFontSizeToFitWidth = true
    }
    
    func makePlaeceholderDynamic(string: String) {
        // Placeholder styling is kept consistent with the field font for a cohesive input experience.
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
                // Ask Auto Layout to re-measure whenever the underlying text content size changes.
                invalidateIntrinsicContentSize()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width != lastWidth else { return }
        lastWidth = bounds.width
        // Width changes affect line wrapping, which affects height.
        invalidateIntrinsicContentSize()
    }
}
