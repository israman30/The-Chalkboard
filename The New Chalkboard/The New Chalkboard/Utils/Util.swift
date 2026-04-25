//
//  Util.swift
//  The New Chalkboard
//
//  Created by Israel Manzo on 2/18/24.
//

import SwiftUI

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


