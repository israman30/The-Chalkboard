import CoreData

/// Core Data managed object for persisted chalkboard items.
///
/// This is intentionally kept lightweight; higher-level operations live in `ChalkboardItemStore`
/// so UI code doesn't need to touch `NSManagedObjectContext` directly.
@objc(CDChalkboardItem)
final class CDChalkboardItem: NSManagedObject {}

extension CDChalkboardItem {
    @nonobjc static func fetchRequest() -> NSFetchRequest<CDChalkboardItem> {
        NSFetchRequest<CDChalkboardItem>(entityName: "CDChalkboardItem")
    }

    @NSManaged var id: String
    @NSManaged var text: String
    @NSManaged var date: Date
    @NSManaged var dueTimeMinutes: NSNumber?
    @NSManaged var isCompleted: Bool
    @NSManaged var sortOrder: Int64
    @NSManaged var prioritySeverityRaw: Int16
}

