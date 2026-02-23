//
// Copyright © 2025 TruVideo. All rights reserved.
//

import CoreData
internal import CoreDataUtilities
import Foundation

final class StreamManagedObject: NSManagedObject, CoreDataQueryable {
    @NSManaged var id: UUID
    @NSManaged var completedAt: Date?
    @NSManaged var createdAt: Date
    @NSManaged var fileType: String
    @NSManaged var fileURL: URL
    @NSManaged var isIncludedInReport: Bool
    @NSManaged var isLibrary: Bool
    @NSManaged var mediaId: UUID?
    @NSManaged var metadata: Data
    @NSManaged var numberOfParts: Int16
    @NSManaged var tags: Data
    @NSManaged var sessionId: String?
    @NSManaged var status: String
    @NSManaged var title: String

    // MARK: - Static Properties

    static var idAttribute: Attribute<UUID> {
        Attribute(\StreamManagedObject.id)
    }
}
