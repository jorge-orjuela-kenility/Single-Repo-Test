//
// Copyright © 2026 TruVideo. All rights reserved.
//

import CoreData
internal import CoreDataUtilities
import Foundation
import TruVideoFoundation

/// A Core Data–backed model that represents a single upload item.
///
/// `UploadModel` acts as a lightweight, identity-based representation of an upload record,
/// suitable for use in lists (`Identifiable`) and hashed collections (`Hashable`).
///
/// The model can be created either from scratch or by decoding values from an
/// `UploadManagedObject`. It also supports writing its current state back to a managed object
/// through `update(_:)`.
@objcMembers
final class MediaUploadModel: Model, Identifiable {
    /// The unique identifier for this upload record.
    let id: UUID

    /// Timestamp indicating when this record was created locally.
    let createdAt: Date

    /// Local filesystem location of the file to upload.
    var filePath: URL

    /// Indicates whether this upload item should be included in generated reports.
    var isIncludedInReport: Bool

    /// Indicates whether the upload item belongs to the library.
    var isLibrary: Bool

    /// Structured metadata associated with the upload item.
    var metadata: Metadata

    /// Identifier assigned by the remote system, if available.
    var remoteId: String?

    /// Remote URL associated with this upload, if available.
    var remoteFileURL: URL?

    /// Current status of the upload workflow.
    var status: MediaUploadStatus

    /// Tags associated with the media item, represented as key–value pairs.
    var tags: [String: String]

    /// Last update timestamp (as stored in persistence), if applicable.
    var updatedAt: Date

    // MARK: - Static Properties

    /// An attribute descriptor for the `Id` property, used for database queries.
    static var idAttribute: Attribute<ID> {
        Attribute(\MediaUploadManagedObject.id)
    }

    /// Attribute descriptor for the `status` property, used to build type-safe queries.
    static var statusAttribute: Attribute<String> {
        Attribute(\MediaUploadManagedObject.status)
    }

    // MARK: - Initializer

    /// Creates a new `UploadModel` instance with the provided values.
    ///
    /// - Parameters:
    ///   - createdAt: Local creation timestamp for the record.
    ///   - filePath: Local filesystem location of the file to upload.
    ///   - isIncludedInReport: Flag indicating whether the item should appear in reports.
    ///   - isLibrary: Flag indicating whether the item belongs to the library.
    ///   - metadata: Structured metadata associated with the upload item.
    ///   - remoteId: Identifier assigned by the remote system, if available.
    ///   - remoteFileURL: Remote URL associated with the upload, if available.
    ///   - status: Current status of the upload workflow.
    ///   - tags: Tags associated with the media item as key–value pairs.
    ///   - updatedAt: Last update timestamp (as stored in persistence), if applicable.
    init(
        createdAt: Date = Date(),
        filePath: URL,
        isIncludedInReport: Bool = false,
        isLibrary: Bool = false,
        metadata: Metadata,
        remoteId: String? = nil,
        remoteFileURL: URL? = nil,
        status: MediaUploadStatus = .idle,
        tags: [String: String],
        updatedAt: Date = Date()
    ) {
        self.id = UUID()
        self.createdAt = createdAt
        self.filePath = filePath
        self.isIncludedInReport = isIncludedInReport
        self.isLibrary = isLibrary
        self.metadata = metadata
        self.remoteId = remoteId
        self.remoteFileURL = remoteFileURL
        self.status = status
        self.tags = tags
        self.updatedAt = updatedAt
    }

    /// Creates a new instance by decoding values from the given managed object.
    ///
    /// This initializer performs JSON decoding for `metadata` and `tags`. If decoding fails
    /// or no stored data is available, the corresponding values default to empty containers.
    ///
    /// - Parameter managedObject: The Core Data entity to decode from.
    init(managedObject: MediaUploadManagedObject) {
        self.id = managedObject.id
        self.createdAt = managedObject.createdAt
        self.filePath = managedObject.filePath
        self.isIncludedInReport = managedObject.isIncludedInReport
        self.isLibrary = managedObject.isLibrary
        self.metadata = Metadata(data: managedObject.metadata ?? Data())
        self.remoteId = managedObject.remoteId
        self.remoteFileURL = managedObject.remoteFileURL
        self.status = MediaUploadStatus(rawValue: managedObject.status) ?? .idle
        self.tags = Dictionary(data: managedObject.tags ?? Data())
        self.updatedAt = managedObject.updatedAt
    }

    // MARK: - Model

    /// Writes the model's current values into the provided managed object.
    ///
    /// - Parameter managedObject: The Core Data entity to update.
    func update(_ managedObject: MediaUploadManagedObject) {
        let decoder = JSONEncoder()

        managedObject.id = id
        managedObject.createdAt = createdAt
        managedObject.filePath = filePath
        managedObject.isIncludedInReport = isIncludedInReport
        managedObject.isLibrary = isLibrary
        managedObject.remoteId = remoteId
        managedObject.remoteFileURL = remoteFileURL
        managedObject.status = status.rawValue
        managedObject.updatedAt = updatedAt

        if let data = try? decoder.encode(metadata) {
            managedObject.metadata = data
        }

        if let data = try? decoder.encode(tags) {
            managedObject.tags = data
        }
    }
}

extension MediaUploadModel: Hashable {
    // MARK: - Hashable

    /// Two `MediaUploadModel` instances are considered equal if they share the same `id`.
    ///
    /// This treats `MediaUploadModel` as an identity-based model: equality depends only on
    /// the stable identifier, not on mutable upload state or metadata.
    static func == (lhs: MediaUploadModel, rhs: MediaUploadModel) -> Bool {
        lhs.id == rhs.id
    }

    /// Hashes the essential component of this model (its `id`) into the provided hasher.
    ///
    /// Using only `id` keeps the hash stable even if other properties (such as `status`)
    /// change, which is important when instances are stored in sets or used as dictionary keys.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

private extension [String: String] {
    /// Creates a dictionary by decoding JSON data into `[String: String]`.
    ///
    /// - Parameter data: Raw JSON payload expected to represent a string dictionary.
    /// - Note: If decoding fails, the dictionary is initialized as empty (`[:]`).
    init(data: Data) {
        let decoder = JSONDecoder()

        self = (try? decoder.decode([String: String].self, from: data)) ?? [:]
    }
}

private extension Metadata {
    /// Creates a `Metadata` value by decoding JSON data.
    ///
    /// - Parameter data: Raw JSON payload expected to represent `Metadata`.
    /// - Note: If decoding fails, `Metadata` is initialized with an empty value (`[:]`).
    init(data: Data) {
        let decoder = JSONDecoder()

        self = (try? decoder.decode(Metadata.self, from: data)) ?? [:]
    }
}
