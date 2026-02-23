//
// Copyright © 2025 TruVideo. All rights reserved.
//

import CoreData
internal import CoreDataUtilities
import Foundation
import TruVideoFoundation

/// A model representing a multipart media upload stream.
///
/// `StreamModel` tracks the overall state and metadata for a media upload that is split into
/// multiple parts. Each stream represents a complete media file (video, audio, etc.) that is
/// being uploaded to cloud storage using a multipart upload strategy. The stream coordinates
/// the upload of its constituent parts and manages the upload session lifecycle.
///
/// Streams are composed of multiple `StreamPartModel` instances, each representing a chunk of
/// the complete media file. The stream tracks the aggregate status and progress of all parts
/// through the upload process.
@objcMembers
final class StreamModel: Model, Identifiable {
    /// A unique identifier for this stream.
    let id: UUID

    /// The date and time when the stream upload was successfully completed.
    ///
    /// `nil` until the stream has been fully uploaded and finalized. Set when all parts have
    /// been successfully uploaded and the multipart session has been completed.
    var completedAt: Date?

    /// The date and time when this stream was created.
    let createdAt: Date

    /// Whether the completed media should be included in reporting or analytics.
    var isIncludedInReport: Bool

    /// Whether the media belongs to a shared or library collection.
    var isLibrary: Bool

    /// The file type of the media being uploaded.
    ///
    /// Specifies the format of the media file (e.g., `.mp4`, `.mov`) and determines how
    /// the stream should be processed and uploaded.
    let fileType: FileType

    /// The local file URL backing this stream, when available.
    var fileURL: URL

    /// The number of parts in the stream.
    var numberOfParts: Int

    /// The identifier of the associated media for this stream.
    var mediaId: UUID?

    /// Arbitrary key–value metadata associated with the media.
    var metadata: Metadata

    /// The identifier of the multipart upload session this stream belongs to.
    ///
    /// `nil` until the stream is initialized with the server and a multipart upload session
    /// is created. Once assigned, this ID is used to coordinate the upload of all stream parts
    /// and finalize the complete upload.
    var sessionId: String?

    /// The current synchronization status of this stream.
    ///
    /// Indicates the state of the stream in the upload lifecycle (e.g., pending, uploading,
    /// completed, failed). Used by operation producers to filter which streams need processing.
    var status: StreamStatus

    /// Key–value tags attached to the media for categorization or filtering.
    var tags: [String: String]

    /// Human-readable title or name of the media.
    var title: String

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
        Attribute(\StreamManagedObject.status)
    }

    // MARK: - Initializer

    /// Creates a new stream model with the specified properties.
    ///
    /// This initializer creates a new stream that is ready to begin the upload process.
    /// The stream is assigned a new unique identifier and initialized with default values
    /// for synchronization state.
    ///
    /// - Parameters:
    ///   - fileType: The file type of the media being uploaded.
    ///   - fileURL: The local file URL backing this stream, when available.
    ///   - attempts: The initial number of synchronization attempts (default: 0).
    ///   - createdAt: The creation timestamp (default: current date and time).
    ///   - numberOfParts: The initial number of parts in the stream.
    ///   - status: The initial synchronization status (default: empty string).
    init(
        fileType: FileType,
        fileURL: URL,
        attempts: Int = 0,
        createdAt: Date = Date(),
        isIncludedInReport: Bool = false,
        isLibrary: Bool = false,
        metadata: Metadata = Metadata(),
        numberOfParts: Int = 0,
        status: StreamStatus = StreamStatus.ready,
        tags: [String: String] = [:],
        title: String = ""
    ) {
        self.id = UUID()
        self.createdAt = createdAt
        self.isIncludedInReport = isIncludedInReport
        self.isLibrary = isLibrary
        self.metadata = metadata
        self.numberOfParts = numberOfParts
        self.fileType = fileType
        self.fileURL = fileURL
        self.status = status
        self.tags = tags
        self.title = title
    }

    /// Creates a new instance by reading values from the given managed object.
    ///
    /// - Parameter managedObject: The Core Data entity to decode from.
    init(managedObject: StreamManagedObject) {
        let decoder = JSONDecoder()

        self.id = managedObject.id
        self.completedAt = managedObject.completedAt
        self.createdAt = managedObject.createdAt
        self.fileType = FileType(rawValue: managedObject.fileType) ?? .unknown
        self.fileURL = managedObject.fileURL
        self.isIncludedInReport = managedObject.isIncludedInReport
        self.isLibrary = managedObject.isLibrary
        self.mediaId = managedObject.mediaId
        self.metadata = (try? decoder.decode(Metadata.self, from: managedObject.metadata)) ?? [:]
        self.numberOfParts = Int(managedObject.numberOfParts)
        self.sessionId = managedObject.sessionId
        self.status = StreamStatus(rawValue: managedObject.status) ?? .ready
        self.tags = (try? decoder.decode([String: String].self, from: managedObject.tags)) ?? [:]
        self.title = managedObject.title
    }

    // MARK: - Model

    /// Updates the specified managed object in the Core Data context.
    ///
    /// This function is intended to apply updates to an existing `StreamManagedObject` instance within the
    /// Core Data context. It allows you to modify the properties of the object, ensuring that the changes
    /// are tracked and eventually saved to the persistent store when the context is saved.
    ///
    /// - Parameter managedObject: The `StreamManagedObject` instance to be updated.
    func update(_ managedObject: StreamManagedObject) {
        let encoder = JSONEncoder()

        managedObject.id = id
        managedObject.completedAt = completedAt
        managedObject.createdAt = createdAt
        managedObject.fileType = fileType.rawValue
        managedObject.fileURL = fileURL
        managedObject.isIncludedInReport = isIncludedInReport
        managedObject.isLibrary = isLibrary
        managedObject.mediaId = mediaId
        managedObject.metadata = (try? encoder.encode(metadata)) ?? Data()
        managedObject.numberOfParts = Int16(numberOfParts)
        managedObject.sessionId = sessionId
        managedObject.status = status.rawValue
        managedObject.tags = (try? encoder.encode(tags)) ?? Data()
        managedObject.title = title
    }
}

extension StreamModel: Hashable {
    // MARK: - Hashable

    /// Two `StreamModel` instances are considered equal if they share the same `id`.
    ///
    /// This treats `StreamModel` as an identity-based value: changes to mutable fields
    /// such as `status` or `attempts` do not affect equality, only the stable `id` does.
    static func == (lhs: StreamModel, rhs: StreamModel) -> Bool {
        lhs.id == rhs.id
    }

    /// Hashes the essential component of this model (its `id`) into the provided hasher.
    ///
    /// Using only `id` keeps the hash stable even if other properties such as `status`
    /// or `attempts` change, which is important if instances are stored in sets or
    /// used as dictionary keys.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
