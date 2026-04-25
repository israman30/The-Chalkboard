import CoreData

@objc(CDChalkboardItem)
final class CDChalkboardItem: NSManagedObject {}

extension CDChalkboardItem {
    @nonobjc static func fetchRequest() -> NSFetchRequest<CDChalkboardItem> {
        NSFetchRequest<CDChalkboardItem>(entityName: "CDChalkboardItem")
    }

    @NSManaged var id: String
    @NSManaged var text: String
    @NSManaged var date: Date
    @NSManaged var isCompleted: Bool
    @NSManaged var sortOrder: Int64
}

