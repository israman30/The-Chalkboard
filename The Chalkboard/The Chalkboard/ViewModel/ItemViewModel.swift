//
//  ItemViewModel.swift
//  The Chalkboard
//
//  Created by Israel Manzo on 4/24/26.
//

import UIKit

protocol ViewStateProtocol {
    var viewState: ViewState<[ChalkboardItem]> { get }
}

class ItemViewModel: ViewStateProtocol {
    var items = [ChalkboardItem]()
    // UI-only state for whether the inline input bar is expanded.
    var isOpen = false
    
    var viewState: ViewState<[ChalkboardItem]> {
        // Keep state derivation trivial: the controller can render empty vs loaded without
        // duplicating “isEmpty” checks throughout the UI code.
        items.isEmpty ? .empty : .loaded(items)
    }
}
