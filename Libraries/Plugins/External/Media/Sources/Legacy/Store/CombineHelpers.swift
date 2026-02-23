//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Combine
import CoreData
import Foundation
internal import TruVideoMediaUpload

/// A utility class that provides static methods for creating Combine publishers
/// related to upload requests and Core Data operations.
final class CombineHelpers {
    // MARK: Initializer

    private init() {}

    // MARK: Static Methods

    /// Creates a publisher that emits the current list of existing uploads.
    /// - Parameter uploads: An array of `LocalUploadRequest` representing the existing uploads.
    /// - Returns: A publisher that emits the provided uploads.
    static func existingUploadsPublisher(
        uploads: [LocalUploadRequest]
    ) -> AnyPublisher<[LocalUploadRequest], Never> {
        CurrentValueSubject<[LocalUploadRequest], Never>(
            uploads
        ).eraseToAnyPublisher()
    }

    /// Creates a publisher that emits a specific existing upload.
    /// - Parameter upload: A `ManagedUpload` object representing the existing upload.
    /// - Returns: A publisher that emits the provided upload.
    static func existingUploadPublisher(
        upload: ManagedUpload
    ) -> AnyPublisher<ManagedUpload, Never> {
        CurrentValueSubject<ManagedUpload, Never>(
            upload
        ).eraseToAnyPublisher()
    }

    /// Creates a publisher that emits the results of a Core Data save action.
    /// - Parameters:
    ///   - context: The `NSManagedObjectContext` in which the save action occurs.
    ///   - mapping: A closure that returns an optional array of `LocalUploadRequest` after saving.
    /// - Returns: A publisher that emits an array of `LocalUploadRequest` when the context saves.
    static func coreDataSaveActionPublisher(
        context: NSManagedObjectContext,
        mapping: @escaping () -> [LocalUploadRequest]?
    ) -> AnyPublisher<[LocalUploadRequest], Never> {
        NotificationCenter.default.publisher(
            for: NSManagedObjectContext.didSaveObjectsNotification,
            object: context
        )
        .map { _ in
            mapping()
        }
        .compactMap { $0 }
        .eraseToAnyPublisher()
    }

    /// Creates a publisher that emits an updated upload request when the specified upload is saved in Core Data.
    /// - Parameters:
    ///   - uploadRequest: The `ManagedUpload` object to observe for updates.
    ///   - context: The `NSManagedObjectContext` where the upload request is stored.
    /// - Returns: A publisher that emits the updated `ManagedUpload` when changes are detected.
    static func coreDataSaveActionPublisher(
        forUpload uploadRequest: ManagedUpload,
        context: NSManagedObjectContext
    ) -> AnyPublisher<ManagedUpload, Never> {
        NotificationCenter.default.publisher(
            for: NSManagedObjectContext.didSaveObjectIDsNotification,
            object: context
        ).map { notification in
            if
                let updatedObjects = notification.userInfo?[NSUpdatedObjectIDsKey] as? Set<NSManagedObjectID>,
                updatedObjects.contains(uploadRequest.objectID),
                let updatedUploadRequest = context.object(with: uploadRequest.objectID) as? ManagedUpload {
                return updatedUploadRequest
            }
            return nil
        }
        .compactMap { $0 }
        .eraseToAnyPublisher()
    }
}
