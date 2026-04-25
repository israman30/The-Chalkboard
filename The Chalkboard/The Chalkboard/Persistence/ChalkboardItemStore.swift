import CoreData

protocol ChalkboardItemStoring {
    func fetchAll() throws -> [ChalkboardItem]
    func create(text: String, date: Date, isCompleted: Bool) throws -> ChalkboardItem
    func update(id: UUID, text: String, date: Date, isCompleted: Bool) throws -> ChalkboardItem
    func setCompleted(id: UUID, isCompleted: Bool) throws -> ChalkboardItem
    func delete(id: UUID) throws
}

final class ChalkboardItemStore: ChalkboardItemStoring {
    static let shared = ChalkboardItemStore()

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    func fetchAll() throws -> [ChalkboardItem] {
        let request = CDChalkboardItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]

        let results = try persistence.viewContext.fetch(request)
        return results.map { $0.toDomain() }
    }

    func create(text: String, date: Date, isCompleted: Bool = false) throws -> ChalkboardItem {
        let ctx = persistence.viewContext

        let item = CDChalkboardItem(context: ctx)
        item.id = UUID().uuidString
        item.text = text
        item.date = date
        item.isCompleted = isCompleted
        item.sortOrder = makeSortOrderNow()

        try persistence.saveIfNeeded()
        return item.toDomain()
    }

    func update(id: UUID, text: String, date: Date, isCompleted: Bool) throws -> ChalkboardItem {
        let ctx = persistence.viewContext
        let item = try fetchEntity(id: id, in: ctx)

        item.text = text
        item.date = date
        item.isCompleted = isCompleted

        try persistence.saveIfNeeded()
        return item.toDomain()
    }

    func setCompleted(id: UUID, isCompleted: Bool) throws -> ChalkboardItem {
        let ctx = persistence.viewContext
        let item = try fetchEntity(id: id, in: ctx)

        item.isCompleted = isCompleted

        try persistence.saveIfNeeded()
        return item.toDomain()
    }

    func delete(id: UUID) throws {
        let ctx = persistence.viewContext
        let item = try fetchEntity(id: id, in: ctx)
        ctx.delete(item)
        try persistence.saveIfNeeded()
    }
}

private extension ChalkboardItemStore {
    func fetchEntity(id: UUID, in context: NSManagedObjectContext) throws -> CDChalkboardItem {
        let request = CDChalkboardItem.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id.uuidString)

        guard let entity = try context.fetch(request).first else {
            throw NSError(
                domain: "ChalkboardItemStore",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Chalkboard item not found."]
            )
        }
        return entity
    }

    func makeSortOrderNow() -> Int64 {
        Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
    }
}

private extension CDChalkboardItem {
    func toDomain() -> ChalkboardItem {
        ChalkboardItem(id: UUID(uuidString: id) ?? UUID(), text: text, date: date, isCompleted: isCompleted)
    }
}

