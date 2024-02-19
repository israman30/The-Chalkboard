//
//  TagModel.swift
//  The New Chalkboard
//
//  Created by Israel Manzo on 2/18/24.
//

import Foundation

struct TagModel: Identifiable, Hashable {
    var id = UUID().uuidString
    var name: String
    var size: CGFloat = 0
}
