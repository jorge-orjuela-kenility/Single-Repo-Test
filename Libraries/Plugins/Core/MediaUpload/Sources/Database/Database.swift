//
// Copyright © 2025 TruVideo. All rights reserved.
//

import CoreData
internal import CoreDataUtilities
import Foundation
import TruVideoFoundation

/// A type alias for types that can be decoded from and encoded to Core Data managed objects.
///
/// `Model` represents types that conform to both `CoreDataDecodable` (can be created from
/// managed objects) and `CoreDataRepresentable` (can update managed objects). This combination
/// enables bidirectional conversion between Swift value types and Core Data entities.
typealias Model = CoreDataDecodable & CoreDataQueryable & CoreDataRepresentable

/// A protocol that defines the interface for database operations.
///
/// Types conforming to `Database` provide a generic interface for performing CRUD operations
/// on model types. The protocol abstracts the underlying storage mechanism, allowing for
/// different implementations (e.g., Core Data, SQLite, in-memory) while maintaining a
/// consistent API.
///
/// ## Model Requirements
///
/// All operations work with types conforming to `Model`, which must be both `CoreDataDecodable`
/// and `CoreDataRepresentable`. This enables seamless conversion between Swift value types and
/// their Core Data managed object counterparts.
///
/// ## Concurrency
///
/// The protocol requires `Sendable` conformance to ensure thread-safe database access across
/// concurrent contexts. Implementations should handle concurrency appropriately, whether through
/// actor isolation, serial queues, or other synchronization mechanisms.
protocol Database: Actor {
    /// Deletes a persisted model instance from storage.
    ///
    /// - Parameter model: The model object to delete.
    /// - Throws: `UtilityError` if the delete operation fails.
    func delete(_ model: some Model) async throws(UtilityError)

    /// Finds a single model instance by its identifier.
    ///
    /// Searches the database for a model instance matching the specified type and identifier.
    /// If no matching instance is found, an error is thrown.
    ///
    /// - Parameters:
    ///   - type: The model type to search for.
    ///   - id: The unique identifier of the model instance.
    /// - Returns: The found model instance.
    /// - Throws: A `UtilityError` if the find operation fails or no instance is found.
    func find<T: Model>(_ type: T.Type, with id: T.ID) async throws(UtilityError) -> T

    /// Observes changes to model instances matching a predicate.
    ///
    /// Returns an async stream that yields arrays of model instances whenever changes occur
    /// in the database that match the specified type and predicate. The stream continues
    /// emitting updates until it is cancelled or the operation completes.
    ///
    /// - Parameters:
    ///   - type: The model type to observe.
    ///   - predicate: The predicate used to filter which instances to observe.
    /// - Returns: An `AsyncStream` that yields arrays of matching model instances as changes occur.
    func observeChanges<T: Model>(of type: T.Type, where predicate: NSPredicate) -> AsyncStream<[T]>

    /// Retrieves all model instances matching a predicate.
    ///
    /// Performs a one-time fetch of all model instances matching the specified type and predicate.
    /// Unlike `observeChanges`, this method returns a single result rather than a stream of updates.
    ///
    /// - Parameters:
    ///   - type: The model type to retrieve.
    ///   - predicate: The predicate used to filter which instances to retrieve.
    /// - Returns: An array of matching model instances.
    /// - Throws: A `UtilityError` if the retrieve operation fails.
    func retrieve<T: Model>(of type: T.Type, where predicate: NSPredicate) throws(UtilityError) -> [T]

    /// Saves multiple model instances to the database.
    ///
    /// Persists changes to multiple model instances in a single operation. If instances with the
    /// same identifiers already exist, they are updated; otherwise, new instances are created.
    /// This method is more efficient than calling `save(_:)` multiple times as it batches the
    /// operations together.
    ///
    /// - Parameter models: An array of model instances to save.
    /// - Throws: A `UtilityError` if the save operation fails.
    func save(_ models: [some Model]) async throws(UtilityError)

    /// Saves a model instance to the database.
    ///
    /// Persists changes to a model instance. If an instance with the same identifier already
    /// exists, it is updated; otherwise, a new instance is created.
    ///
    /// - Parameter model: The model instance to save.
    /// - Throws: A `UtilityError` if the save operation fails.
    func save(_ model: some Model) async throws(UtilityError)
}

extension Database {
    /// Observes changes to all instances of a model type.
    ///
    /// Convenience method that observes all instances of a type without filtering. Equivalent
    /// to calling `observeChanges(of:where:)` with a predicate that matches all instances.
    ///
    /// - Parameter type: The model type to observe.
    /// - Returns: An `AsyncStream` that yields arrays of all model instances as changes occur.
    func observeChanges<T: Model>(of type: T.Type) -> AsyncStream<[T]> {
        observeChanges(of: type, where: NSPredicate(value: true))
    }

    /// Retrieves all instances of a model type.
    ///
    /// Convenience method that retrieves all instances of a type without filtering. Equivalent
    /// to calling `retrieve(of:where:)` with a predicate that matches all instances.
    ///
    /// - Parameter type: The model type to retrieve.
    /// - Returns: An array of all model instances.
    /// - Throws: A `UtilityError` if the retrieve operation fails.
    func retrieve<T: Model>(of type: T.Type) throws -> [T] {
        try retrieve(of: type, where: NSPredicate(value: true))
    }
}

/// A Core Data implementation of the `Database` protocol.
///
/// `CoreDataDatabase` provides database operations using Core Data as the underlying storage
/// mechanism. It uses an actor to ensure thread-safe access to the persistent container and
/// manages Core Data contexts appropriately for read and write operations.
///
/// ## Context Management
///
/// - Read operations (`find`, `retrieve`) use the view context for optimal performance
/// - Write operations (`save`) use a background context to avoid blocking the main thread
/// - Change observation uses the view context to monitor updates
///
/// ## Thread Safety
///
/// The actor isolation ensures that all database operations are serialized, preventing data
/// races and ensuring consistent state. Operations are performed on the appropriate Core Data
/// contexts to maintain thread safety.
actor CoreDataDatabase: Database {
    // MARK: - Private Properties

    /// The persistent container that manages the Core Data stack.
    private let persistentContainer: NSPersistentContainer

    // MARK: - Types

    /// Errors specific to Core Data operations.
    enum CoreDataError: Error {
        /// Indicates that a requested entity was not found in the database.
        case notFound
    }

    // MARK: - Initializer

    /// Creates a new Core Data database instance.
    ///
    /// - Parameter persistentContainer: The persistent container to use for database operations.
    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }

    // MARK: - Database

    /// Deletes a persisted model instance from storage.
    ///
    /// - Parameter model: The model object to delete.
    /// - Throws: `UtilityError` if the delete operation fails.
    func delete<T: Model>(_ model: T) async throws(UtilityError) {
        do {
            return try persistentContainer.viewContext.performAndWait {
                try persistentContainer.newQuery(of: T.ManagedObject.self)
                    .filter(T.idAttribute == model.id)
                    .delete()
            }
        } catch {
            throw UtilityError(kind: .DatabaseError.deletionFailed, underlyingError: error)
        }
    }

    /// Observes changes to model instances matching a predicate.
    ///
    /// Creates a query that observes changes to Core Data entities matching the specified
    /// type and predicate. As changes occur, the stream yields arrays of converted model
    /// instances. The observation continues until the stream is cancelled.
    ///
    /// - Parameters:
    ///   - type: The model type to observe.
    ///   - predicate: The predicate used to filter which instances to observe.
    /// - Returns: An `AsyncStream` that yields arrays of matching model instances as changes occur.
    func observeChanges<T: Model>(of type: T.Type, where predicate: NSPredicate) -> AsyncStream<[T]> {
        AsyncStream { continuation in
            let task = Task {
                let query = try persistentContainer
                    .newQuery(of: T.ManagedObject.self)
                    .filter(predicate)

                for try await snapshot in query.observe() {
                    let elements = await persistentContainer.viewContext.perform {
                        snapshot.elements.map(T.init(managedObject:))
                    }

                    continuation.yield(elements)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Finds a single model instance by its identifier.
    ///
    /// Searches the view context for a managed object matching the specified type and identifier,
    /// then converts it to a model instance. Throws an error if no matching instance is found.
    ///
    /// - Parameters:
    ///   - type: The model type to search for.
    ///   - id: The unique identifier of the model instance.
    /// - Returns: The found model instance.
    /// - Throws: A `UtilityError` with kind `.DatabaseError.findFailed` if the operation fails
    ///           or no instance is found.
    func find<T: Model>(_ type: T.Type, with id: T.ID) async throws(UtilityError) -> T {
        do {
            return try persistentContainer.viewContext.performAndWait {
                let model = try persistentContainer.newQuery(of: T.ManagedObject.self)
                    .filter(T.idAttribute == id)
                    .first()
                    .unwrap(or: CoreDataError.notFound)

                return T(managedObject: model)
            }
        } catch {
            throw UtilityError(kind: .DatabaseError.findFailed, underlyingError: error)
        }
    }

    /// Retrieves all model instances matching a predicate.
    ///
    /// Performs a fetch operation on the view context for managed objects matching the specified
    /// type and predicate, then converts them to model instances.
    ///
    /// - Parameters:
    ///   - type: The model type to retrieve.
    ///   - predicate: The predicate used to filter which instances to retrieve.
    /// - Returns: An array of matching model instances.
    /// - Throws: A `UtilityError` with kind `.DatabaseError.retrieveFailed` if the operation fails.
    func retrieve<T: Model>(of type: T.Type, where predicate: NSPredicate) throws(UtilityError) -> [T] {
        do {
            return try persistentContainer.viewContext.performAndWait {
                try persistentContainer.newQuery(of: T.ManagedObject.self)
                    .filter(predicate)
                    .array()
                    .map(T.init(managedObject:))
            }
        } catch {
            throw UtilityError(kind: .DatabaseError.retrieveFailed, underlyingError: error)
        }
    }

    /// Saves multiple model instances to the database.
    ///
    /// Creates or updates managed objects in a background context based on the model instances.
    /// For each model, if a managed object with the same identifier exists, it is updated;
    /// otherwise, a new managed object is created. All changes are then saved to the persistent
    /// store in a single batch operation, which is more efficient than saving instances individually.
    ///
    /// The operation uses a background context with automatic merging enabled and a merge policy
    /// that prioritizes store values over in-memory values to handle concurrent modifications.
    ///
    /// - Parameter models: An array of model instances to save.
    /// - Throws: A `UtilityError` with kind `.DatabaseError.saveFailed` if the operation fails.
    func save<T: Model>(_ models: [T]) async throws(UtilityError) {
        do {
            let context = persistentContainer.newBackgroundContext()

            context.automaticallyMergesChangesFromParent = true
            context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy

            try await context.performAndSave {
                for model in models {
                    let managedObject = try context.newQuery(of: T.ManagedObject.self)
                        .filter(T.idAttribute == model.id)
                        .first() ?? T.ManagedObject(context: context)

                    model.update(managedObject)
                }
            }
        } catch {
            throw UtilityError(kind: .DatabaseError.saveFailed, underlyingError: error)
        }
    }

    /// Saves a model instance to the database.
    ///
    /// Creates or updates a managed object in a background context based on the model instance.
    /// If a managed object with the same identifier exists, it is updated; otherwise, a new
    /// managed object is created. The changes are then saved to the persistent store.
    ///
    /// - Parameter model: The model instance to save.
    /// - Throws: A `UtilityError` with kind `.DatabaseError.saveFailed` if the operation fails.
    func save(_ model: some Model) async throws(UtilityError) {
        try await save([model])
    }
}

extension NSPredicate: @unchecked @retroactive Sendable {}
