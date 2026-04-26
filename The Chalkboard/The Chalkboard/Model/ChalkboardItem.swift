//
//  ChalkboardItem.swift
//  The Chalkboard
//
//  Created by Israel Manzo on 4/24/26.
//
import UIKit

/// Value-type “domain model” used by the UI.
///
/// The persistence layer is responsible for mapping to/from Core Data entities.
struct ChalkboardItem: Equatable {
    var id: UUID = UUID()
    var text: String
    var date: Date
    var isCompleted: Bool = false
}

