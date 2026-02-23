//
// Copyright © 2025 TruVideo. All rights reserved.
//

import CoreData

/// A protocol that defines a type that can be mapped to a corresponding Core Data `NSManagedObject`.
///
/// The `CoreDataRepresentable` protocol is intended to bridge the gap between a model object and its corresponding Core
/// Data entity.
/// Types conforming to this protocol are expected to define how they can be converted or mapped into a Core Data
/// `NSManagedObject` subclass.
///
/// ### Associated Types:
/// - `ManagedObject`: The type of `NSManagedObject` that the conforming type maps to.
///
/// ### Example Usage:
/// ```swift
/// struct User: CoreDataRepresentable {
///     typealias ManagedObject = UserEntity
///
///     let id: UUID
///     let name: String
///
///     func map(_ managedObject: UserEntity) {
///         managedObject.id = id
///         managedObject.name = name
///     }
/// }
/// ```
public protocol CoreDataRepresentable: Identifiable {
    /// The type of `NSManagedObject` that the conforming type maps to.
    associatedtype ManagedObject: NSManagedObject & CoreDataQueryable

    /// Updates the specified managed object in the Core Data context.
    ///
    /// This function is intended to apply updates to an existing `NSManagedObject` instance within the
    /// Core Data context. It allows you to modify the properties of the object, ensuring that the changes
    /// are tracked and eventually saved to the persistent store when the context is saved.
    ///
    /// - Parameter managedObject: The `NSManagedObject` instance to be updated.
    func update(_ managedObject: ManagedObject)
}
