import CoreData

/// App-wide Core Data stack.
///
/// The goal of this type is to centralize Core Data configuration and provide a single
/// `NSPersistentContainer` + `viewContext` that can be reused across the app.
///
/// Notes:
/// - The container name **must** match your `.xcdatamodeld` file (`ChalkboardModel`).
/// - In Xcode Previews we use an in-memory store so previews don't write to disk.
final class PersistenceController {
    static let shared: PersistenceController = {
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        return PersistenceController(inMemory: isPreview)
    }()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ChalkboardModel")

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        // Ensure model changes like added attributes can migrate without a custom mapping model.
        container.persistentStoreDescriptions.forEach { description in
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }

        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("Failed to load Core Data store: \(error)")
            }
        }

        // Favor in-memory changes when the same object is edited in multiple contexts.
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Keeps `viewContext` up to date when background contexts save.
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    /// Saves the given context (or `viewContext`) only if there are changes.
    func saveIfNeeded(context: NSManagedObjectContext? = nil) throws {
        let ctx = context ?? viewContext
        guard ctx.hasChanges else { return }
        try ctx.save()
    }

    /// Runs work on a background context owned by the container.
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }
}

