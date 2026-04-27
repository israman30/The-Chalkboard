//
//  ChalkboardItem.swift
//  The Chalkboard
//
//  Created by Israel Manzo on 4/24/26.
//
import UIKit

enum ChalkboardItemPrioritySeverity: Int16, CaseIterable, Equatable {
    case low = 0
    case medium = 1
    case high = 2

    static let noneRawValue: Int16 = -1

    var title: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }

    var tagColor: UIColor {
        switch self {
        case .low: UIColor.systemGreen
        case .medium: UIColor.systemYellow
        case .high: UIColor.systemRed
        }
    }

    var tagForegroundColor: UIColor { .white }

    var systemImageName: String { "flag.fill" }
}

/// Value-type “domain model” used by the UI.
///
/// The persistence layer is responsible for mapping to/from Core Data entities.
struct ChalkboardItem: Equatable {
    var id: UUID = UUID()
    var text: String
    var date: Date
    var isCompleted: Bool = false
    var prioritySeverity: ChalkboardItemPrioritySeverity? = nil
}

