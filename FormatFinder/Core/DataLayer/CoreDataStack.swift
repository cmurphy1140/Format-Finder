import CoreData
import Foundation

// MARK: - Core Data Stack

final class CoreDataStack {
    static let shared = CoreDataStack()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FormatFinder")
        
        // Enable automatic migrations
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("Core Data failed to load: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func save() {
        guard viewContext.hasChanges else { return }
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save Core Data context: \(error)")
        }
    }
    
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await persistentContainer.performBackgroundTask { context in
            try block(context)
        }
    }
}

// MARK: - Migration Manager

final class MigrationManager {
    static func performMigrationIfNeeded() {
        let currentVersion = UserDefaults.standard.integer(forKey: "DataModelVersion")
        let targetVersion = 1
        
        guard currentVersion < targetVersion else { return }
        
        // Perform migrations
        switch currentVersion {
        case 0:
            migrateFromV0ToV1()
        default:
            break
        }
        
        UserDefaults.standard.set(targetVersion, forKey: "DataModelVersion")
    }
    
    private static func migrateFromV0ToV1() {
        // Initial setup - no migration needed
    }
}