//
// Copyright © 2025 TruVideo. All rights reserved.
//

import CoreData
import TruVideoFoundation

extension NSManagedObject {
    /// Finds or creates a Core Data model object of the specified type, matching a given predicate,
    /// within an asynchronous context.
    ///
    /// This method performs a "find or create" operation, meaning it attempts to find an existing object
    /// in the Core Data store that matches the provided predicate. If no matching object is found, it creates
    /// and returns a new instance of the specified model. The method uses Swift's `async`/`await`
    /// concurrency model and throws an error if any step of the operation fails.
    ///
    /// - Parameters:
    ///   - predicate: The `NSPredicate` used to search for existing objects in the Core Data store. This predicate
    ///                defines the conditions that an existing object must meet to be returned.
    ///   - context: The `NSManagedObjectContext` within which the operation should be performed.
    ///              The context is used for both fetching and creating the object if necessary.
    /// - Throws: An error if the operation fails.
    /// - Returns: A `Model`, which is either the first object found that matches the predicate or a newly
    ///            created instance of the `Model` type if no matching object is found.
    public static func findOrCreate(
        matching predicate: NSPredicate,
        in context: NSManagedObjectContext
    ) throws -> Self {
        guard let entityName = entity().name else {
            throw UtilityError(kind: .CoreDataKitErrorReason.invalidEntityName)
        }

        return try Query(entityName, context: context)
            .filter(predicate)
            .first() ?? Self(context: context)
    }

    /// Finds an entity matching the specified predicate in the given managed object context.
    ///
    /// This method performs an asynchronous search operation to locate an entity that matches
    /// the provided predicate criteria. The search is executed in the specified Core Data
    /// context, allowing for safe, concurrent database queries.
    ///
    /// ## Predicate Matching
    /// The method searches through all entities of the same type in the context,
    /// returning the first entity that matches the predicate criteria.
    ///
    /// ## Usage Example
    /// ```swift
    /// // Find a user by email
    /// let predicate = NSPredicate(format: "email == %@", emailAddress)
    /// let user = try await User.find(matching: predicate, in: context)
    ///
    /// // Find an upload by order
    /// let orderPredicate = NSPredicate(format: "order == %d", orderNumber)
    /// let upload = try await UploadPart.find(matching: orderPredicate, in: context)
    ///
    /// // Find an entity with compound conditions
    /// let compoundPredicate = NSPredicate(format: "status == %@ AND createdAt > %@",
    ///                                     status, date)
    /// let entity = try await MyEntity.find(matching: compoundPredicate, in: context)
    /// ```
    ///
    /// - Parameters:
    ///    - predicate: The search criteria to match against entity attributes
    ///    - context: The Core Data managed object context to search in
    /// - Returns: An entity instance matching the predicate
    /// - Throws: `entityNotFound` if no entity matches, or Core Data errors
    public static func find(matching predicate: NSPredicate, in context: NSManagedObjectContext) throws -> Self {
        guard let entityName = entity().name else {
            throw UtilityError(kind: .CoreDataKitErrorReason.invalidEntityName)
        }

        return try Query(entityName, context: context)
            .filter(predicate)
            .first()
            .unwrap(or: UtilityError(kind: .CoreDataKitErrorReason.entityNotFound, failureReason: "Entity not found"))
    }
}
