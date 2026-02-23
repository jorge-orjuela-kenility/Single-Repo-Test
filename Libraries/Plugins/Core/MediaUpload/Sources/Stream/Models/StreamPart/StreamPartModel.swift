//
// Copyright © 2025 TruVideo. All rights reserved.
//

import CoreData
internal import CoreDataUtilities
import Foundation

/// A model representing a single part of a multipart stream upload.
///
/// `StreamPartModel` tracks the synchronization state and metadata for an individual chunk
/// of a larger media stream. Each part represents a segment of the overall stream that needs
/// to be uploaded to cloud storage as part of a multipart upload session.
@objcMembers
final class StreamPartModel: Model, @unchecked Sendable {
    /// A unique identifier for this stream part.
    let id: UUID

    /// The number of synchronization attempts made for this part.
    ///
    /// Incremented each time a sync operation is attempted. Parts with fewer than 5 attempts
    /// are eligible for retry operations.
    var attempts: Int

    /// The date and time when the part upload was successfully completed.
    ///
    /// `nil` if the part has not yet been completed. Set when the upload finishes and
    /// an `eTag` is received from storage.
    var completedAt: Date?

    /// The date and time when this part was created.
    let createdAt: Date

    /// The entity tag (ETag) received from storage after successful upload.
    ///
    /// `nil` until the part has been successfully uploaded. The ETag is returned by the
    /// storage service and is required for finalizing the multipart upload session.
    var eTag: String?

    /// The local file system URL where the part's data is stored.
    ///
    /// This URL points to the chunk of media data that corresponds to this part and
    /// will be uploaded to cloud storage.
    var localFileUrl: URL

    /// The date and time when the next synchronization attempt should be made.
    ///
    /// `nil` if the part is ready for immediate retry or has not yet failed. Set when a
    /// synchronization attempt fails to implement exponential backoff or scheduled retry logic.
    /// Operation producers can use this property to filter parts that are ready for retry.
    var nextAttemptDate: Date?

    /// The sequential part number within the stream.
    ///
    /// Parts are numbered sequentially starting from 1, indicating their order within
    /// the complete stream. This number is used when uploading and finalizing the
    /// multipart session.
    let number: Int

    /// The current synchronization status of this part.
    ///
    /// Indicates the state of the part in the upload lifecycle (e.g., pending, uploading,
    /// completed, failed). Used by operation producers to filter which parts need processing.
    var status: StreamPartStatus

    /// The unique identifier of the stream this part belongs to.
    ///
    /// Links this part to its parent stream, allowing the system to track all parts
    /// associated with a particular media upload.
    var streamId: UUID

    // MARK: - Static Properties

    /// An attribute descriptor for the `id` property, used for database queries.
    ///
    /// Provides type-safe access to the `id` field when building predicates for Core Data
    /// queries or observations.
    static var idAttribute: Attribute<ID> {
        Attribute(\StreamPartManagedObject.id)
    }

    /// An attribute descriptor for the `status` property, used for database queries.
    ///
    /// Provides type-safe access to the `status` field when building predicates for filtering
    /// parts by their synchronization status. Commonly used in queries to find parts that
    /// match specific status values.
    static var statusAttribute: Attribute<String> {
        Attribute(\StreamPartManagedObject.status)
    }

    // MARK: - Initializer

    /// Creates a new stream part model with the specified properties.
    ///
    /// This initializer creates a new part that is ready to be synchronized. The part
    /// is assigned a new unique identifier and initialized with default values for
    /// synchronization state.
    ///
    /// - Parameters:
    ///   - localFileUrl: The local file system URL where the part's data is stored.
    ///   - number: The sequential part number within the stream (typically 1-based).
    ///   - sessionId: The unique identifier of the stream this part belongs to.
    ///   - streamId: The unique identifier of the parent stream this part belongs to.
    ///   - attempts: The initial number of synchronization attempts (default: 0).
    ///   - createdAt: The creation timestamp (default: current date and time).
    ///   - status: The initial synchronization status.
    init(
        localFileUrl: URL,
        number: Int,
        sessionId: String?,
        streamId: UUID,
        attempts: Int = 0,
        createdAt: Date = Date(),
        status: StreamPartStatus = StreamPartStatus.pending
    ) {
        self.id = UUID()
        self.attempts = attempts
        self.createdAt = createdAt
        self.localFileUrl = localFileUrl
        self.number = number
        self.status = status
        self.streamId = streamId
    }

    /// Creates a new instance by reading values from the given managed object.
    ///
    /// - Parameter managedObject: The Core Data entity to decode from.
    init(managedObject: StreamPartManagedObject) {
        self.id = managedObject.id
        self.attempts = Int(managedObject.attempts)
        self.completedAt = managedObject.completedAt
        self.createdAt = managedObject.createdAt
        self.eTag = managedObject.eTag
        self.localFileUrl = managedObject.localFileUrl.resolvingUrlInContainer()
        self.nextAttemptDate = managedObject.nextAttemptDate
        self.number = Int(managedObject.number)
        self.status = StreamPartStatus(rawValue: managedObject.status) ?? .pending
        self.streamId = managedObject.streamId
    }

    // MARK: - Model

    /// Updates the specified managed object in the Core Data context.
    ///
    /// This function is intended to apply updates to an existing `StreamPartManagedObject` instance within the
    /// Core Data context. It allows you to modify the properties of the object, ensuring that the changes
    /// are tracked and eventually saved to the persistent store when the context is saved.
    ///
    /// - Parameter managedObject: The `StreamPartManagedObject` instance to be updated.
    func update(_ managedObject: StreamPartManagedObject) {
        managedObject.id = id
        managedObject.attempts = Int16(attempts)
        managedObject.completedAt = completedAt
        managedObject.createdAt = createdAt
        managedObject.eTag = eTag
        managedObject.localFileUrl = localFileUrl
        managedObject.nextAttemptDate = nextAttemptDate
        managedObject.number = Int16(number)
        managedObject.status = status.rawValue
        managedObject.streamId = streamId
    }
}

private extension URL {
    /// Resolves a stream file URL against the current sandbox location.
    ///
    /// Returns `self` if the file exists at the original path. Otherwise, it rebuilds
    /// the URL using `URL.streamsDirectory` plus `lastPathComponent`, which helps when
    /// stored absolute paths become stale after container path changes.
    ///
    /// - Returns: A URL pointing to the existing file location, if resolvable.
    /// - Note: Persist only the relative file path and rebuild the absolute URL on launch.
    /// App sandbox container paths can change across installs/updates, so storing
    /// absolute URLs may break file lookup.
    func resolvingUrlInContainer() -> URL {
        let fileExists = FileManager.default.fileExists(atPath: path)

        return fileExists ? self : URL.streamsDirectory.appendingPathComponent(lastPathComponent)
    }
}
