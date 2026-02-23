//
// Copyright © 2025 TruVideo. All rights reserved.
//

import CoreData

/// A protocol for types that can be initialized **from** a Core Data managed object.
///
/// `CoreDataDecodable` is the counterpart of `CoreDataRepresentable`.
/// While `CoreDataRepresentable` describes how a domain/DTO type writes its data
/// **into** Core Data, `CoreDataDecodable` describes how a domain/DTO type can be
/// **built from** an existing `NSManagedObject`.
///
/// Conforming types declare which managed-object type they decode from
/// (via the `ManagedObject` associated type) and provide an initializer that maps
/// the Core Data values into their own properties.
///
/// Typical usage:
///
/// ```swift
/// struct UserDTO: CoreDataDecodable {
///     typealias ManagedObject = UserEntity
///
///     let id: UUID
///     let name: String
///     let email: String?
///
///     init(managedObject: UserEntity) {
///         self.id = managedObject.id
///         self.name = managedObject.name
///         self.email = managedObject.email
///     }
/// }
/// ```
///
/// You can combine this with `CoreDataRepresentable` to make a type
/// round-trippable (Core Data → DTO → Core Data).
public protocol CoreDataDecodable: Identifiable {
    /// The Core Data managed-object type this value can be decoded from.
    associatedtype ManagedObject: CoreDataQueryable

    /// Creates a new instance by reading values from the given managed object.
    ///
    /// - Parameter managedObject: The Core Data entity to decode from.
    init(managedObject: ManagedObject)
}
