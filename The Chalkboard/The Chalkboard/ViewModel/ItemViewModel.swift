//
//  ItemViewModel.swift
//  The Chalkboard
//
//  Created by Israel Manzo on 4/24/26.
//

import UIKit

class ItemViewModel {
    var items = [ChalkboardItem]()
    var isOpen = false
    
    var viewState: ViewState<[ChalkboardItem]> {
        items.isEmpty ? .empty : .loaded(items)
    }
}
