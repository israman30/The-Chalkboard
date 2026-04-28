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

extension UITextView {
    /// Adds basic Markdown list continuation behavior when the user presses Return.
    /// Supports:
    /// - Unordered lists: `- `, `* `, `+ `, `• `
    /// - Ordered lists: `1. `, `1) `
    /// - Task lists: `- [ ] `, `- [x] ` (continues with unchecked)
    ///
    /// Behavior:
    /// - Return at end of a list line continues the list on the next line.
    /// - Return on an empty list item removes the marker and exits the list.
    func applyMarkdownListContinuationIfNeeded(in range: NSRange, replacementText: String) -> Bool {
        guard replacementText == "\n" else { return true }
        guard let text = self.text else { return true }
        guard range.length == 0 else { return true } // keep behavior predictable for now

        let ns = text as NSString
        let caret = range.location
        guard caret <= ns.length else { return true }

        let lineRange = ns.lineRange(for: NSRange(location: caret, length: 0))
        let lineEnd = lineRange.location + lineRange.length
        let endsWithNewline = lineEnd > 0 && lineEnd <= ns.length && ns.character(at: lineEnd - 1) == 10
        let contentEnd = endsWithNewline ? (lineEnd - 1) : lineEnd

        // Only continue lists when the user hits Return at end of line.
        guard caret == contentEnd else { return true }

        let contentLen = max(0, contentEnd - lineRange.location)
        let line = ns.substring(with: NSRange(location: lineRange.location, length: contentLen))
        guard let marker = MarkdownListMarker.parse(line: line) else { return true }

        let remainder = String(line.dropFirst(marker.fullPrefix.utf16.count))
        let isEmptyItem = remainder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if isEmptyItem {
            // Replace the current (marker-only) line content with a bare newline to "exit" the list.
            let replaceRange = NSRange(location: lineRange.location, length: contentLen)
            let updated = ns.replacingCharacters(in: replaceRange, with: "\n")
            self.text = updated
            self.selectedRange = NSRange(location: lineRange.location + 1, length: 0)
            self.delegate?.textViewDidChange?(self)
            return false
        }

        let insert = "\n" + marker.nextLinePrefix
        let updated = ns.replacingCharacters(in: range, with: insert)
        self.text = updated
        self.selectedRange = NSRange(location: caret + insert.utf16.count, length: 0)
        self.delegate?.textViewDidChange?(self)
        return false
    }
}

private struct MarkdownListMarker {
    let indentation: String
    let kind: Kind

    enum Kind {
        case unordered(bullet: String)
        case ordered(number: Int, delimiter: String)
        case task(bullet: String)
    }

    var fullPrefix: String {
        switch kind {
        case let .unordered(bullet):
            return indentation + bullet + " "
        case let .ordered(number, delimiter):
            return indentation + "\(number)\(delimiter) "
        case let .task(bullet):
            return indentation + bullet + " [ ] "
        }
    }

    var nextLinePrefix: String {
        switch kind {
        case let .unordered(bullet):
            return indentation + bullet + " "
        case let .ordered(number, delimiter):
            return indentation + "\(number + 1)\(delimiter) "
        case let .task(bullet):
            return indentation + bullet + " [ ] "
        }
    }

    static func parse(line: String) -> MarkdownListMarker? {
        // Capture leading indentation (spaces/tabs).
        var indentEnd = line.startIndex
        while indentEnd < line.endIndex, line[indentEnd] == " " || line[indentEnd] == "\t" {
            indentEnd = line.index(after: indentEnd)
        }
        let indentation = String(line[..<indentEnd])
        let rest = String(line[indentEnd...])

        // Task lists: "- [ ] " / "- [x] " / "* [ ] " / "• [x] "
        if let bullet = matchTaskPrefix(rest: rest) {
            return MarkdownListMarker(indentation: indentation, kind: .task(bullet: bullet))
        }

        // Unordered: "- " / "* " / "+ " / "• "
        if let bullet = matchUnorderedPrefix(rest: rest) {
            return MarkdownListMarker(indentation: indentation, kind: .unordered(bullet: bullet))
        }

        // Ordered: "1. " / "1) "
        if let ordered = matchOrderedPrefix(rest: rest) {
            return MarkdownListMarker(indentation: indentation, kind: .ordered(number: ordered.number, delimiter: ordered.delimiter))
        }

        return nil
    }

    private static func matchUnorderedPrefix(rest: String) -> String? {
        let bullets = ["- ", "* ", "+ ", "• "]
        for b in bullets where rest.hasPrefix(b) {
            return String(b.dropLast()) // bullet character only
        }
        return nil
    }

    private static func matchTaskPrefix(rest: String) -> String? {
        // Minimal parser without regex to keep this lightweight.
        // Accept bullet + space + [ ]/[x]/[X] + space
        let bullets = ["-", "*", "+", "•"]
        for bullet in bullets {
            let prefix1 = bullet + " ["
            guard rest.hasPrefix(prefix1) else { continue }
            guard rest.count >= prefix1.count + 3 else { continue } // "] " after the checkbox
            let idx = rest.index(rest.startIndex, offsetBy: prefix1.count)
            let char = rest[idx]
            guard char == " " || char == "x" || char == "X" else { continue }
            let idxClose = rest.index(after: idx)
            guard idxClose < rest.endIndex, rest[idxClose] == "]" else { continue }
            let idxSpace = rest.index(after: idxClose)
            guard idxSpace < rest.endIndex, rest[idxSpace] == " " else { continue }
            return bullet
        }
        return nil
    }

    private static func matchOrderedPrefix(rest: String) -> (number: Int, delimiter: String)? {
        // Parse leading digits, then "." or ")", then a space.
        var digits = ""
        var i = rest.startIndex
        while i < rest.endIndex, rest[i].isNumber {
            digits.append(rest[i])
            i = rest.index(after: i)
        }
        guard !digits.isEmpty else { return nil }
        guard i < rest.endIndex else { return nil }
        let delimiter = rest[i]
        guard delimiter == "." || delimiter == ")" else { return nil }
        let afterDelim = rest.index(after: i)
        guard afterDelim < rest.endIndex, rest[afterDelim] == " " else { return nil }
        return (number: Int(digits) ?? 1, delimiter: String(delimiter))
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
