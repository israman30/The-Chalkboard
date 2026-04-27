import CoreData

/// Minimal CRUD surface used by the UI layer.
///
/// This protocol makes it easy to swap the backing store later (e.g. mock store for tests),
/// while keeping the UI code focused on app behavior rather than Core Data APIs.
protocol ChalkboardItemStoring {
    func fetchAll() throws -> [ChalkboardItem]
    func create(text: String, date: Date, dueTimeMinutes: Int?, isCompleted: Bool, prioritySeverity: ChalkboardItemPrioritySeverity?) throws -> ChalkboardItem
    func update(id: UUID, text: String, date: Date, dueTimeMinutes: Int?, isCompleted: Bool, prioritySeverity: ChalkboardItemPrioritySeverity?) throws -> ChalkboardItem
    func setCompleted(id: UUID, isCompleted: Bool) throws -> ChalkboardItem
    func delete(id: UUID) throws
}

/// Core Data-backed implementation of `ChalkboardItemStoring`.
///
/// This store converts between:
/// - `CDChalkboardItem` (Core Data) and
/// - `ChalkboardItem` (value-type domain model used by the UI).
final class ChalkboardItemStore: ChalkboardItemStoring {
    static let shared = ChalkboardItemStore()

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    // MARK: - Read

    /// Fetches all items ordered by creation time (`sortOrder`).
    func fetchAll() throws -> [ChalkboardItem] {
        let request = CDChalkboardItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]

        let results = try persistence.viewContext.fetch(request)
        return results.map { $0.toDomain() }
    }

    // MARK: - Create

    func create(text: String, date: Date, dueTimeMinutes: Int?, isCompleted: Bool, prioritySeverity: ChalkboardItemPrioritySeverity?) throws -> ChalkboardItem {
        let ctx = persistence.viewContext

        let item = CDChalkboardItem(context: ctx)
        // Stored as a String (UUID attributes require older model formats in some toolchains).
        item.id = UUID().uuidString
        item.text = text
        item.date = date
        item.dueTimeMinutes = dueTimeMinutes.map { NSNumber(value: Int32($0)) }
        item.isCompleted = isCompleted
        item.sortOrder = makeSortOrderNow()
        item.prioritySeverityRaw = prioritySeverity?.rawValue ?? ChalkboardItemPrioritySeverity.noneRawValue

        try persistence.saveIfNeeded()
        return item.toDomain()
    }

    // MARK: - Update

    func update(id: UUID, text: String, date: Date, dueTimeMinutes: Int?, isCompleted: Bool, prioritySeverity: ChalkboardItemPrioritySeverity?) throws -> ChalkboardItem {
        let ctx = persistence.viewContext
        let item = try fetchEntity(id: id, in: ctx)

        item.text = text
        item.date = date
        item.dueTimeMinutes = dueTimeMinutes.map { NSNumber(value: Int32($0)) }
        item.isCompleted = isCompleted
        item.prioritySeverityRaw = prioritySeverity?.rawValue ?? ChalkboardItemPrioritySeverity.noneRawValue

        try persistence.saveIfNeeded()
        return item.toDomain()
    }

    // MARK: - Update (partial)

    func setCompleted(id: UUID, isCompleted: Bool) throws -> ChalkboardItem {
        let ctx = persistence.viewContext
        let item = try fetchEntity(id: id, in: ctx)

        item.isCompleted = isCompleted

        try persistence.saveIfNeeded()
        return item.toDomain()
    }

    // MARK: - Delete

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
        // Store UUIDs as strings to keep the Core Data model/tooling simple across versions.
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
        // Milliseconds since epoch gives a stable “insertion order” that’s easy to sort by.
        Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
    }
}

private extension CDChalkboardItem {
    func toDomain() -> ChalkboardItem {
        let severity: ChalkboardItemPrioritySeverity? = {
            if prioritySeverityRaw == ChalkboardItemPrioritySeverity.noneRawValue { return nil }
            return ChalkboardItemPrioritySeverity(rawValue: prioritySeverityRaw)
        }()

        return ChalkboardItem(
            id: UUID(uuidString: id) ?? UUID(),
            text: text,
            date: date,
            dueTimeMinutes: dueTimeMinutes?.intValue,
            isCompleted: isCompleted,
            prioritySeverity: severity
        )
    }
}

