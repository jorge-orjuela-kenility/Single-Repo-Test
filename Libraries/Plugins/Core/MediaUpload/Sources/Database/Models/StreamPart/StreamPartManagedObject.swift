//
// Copyright © 2025 TruVideo. All rights reserved.
//

import CoreData
internal import CoreDataUtilities
import Foundation

final class StreamPartManagedObject: NSManagedObject, CoreDataQueryable {
    @NSManaged var id: UUID
    @NSManaged var attempts: Int16
    @NSManaged var completedAt: Date?
    @NSManaged var createdAt: Date
    @NSManaged var eTag: String?
    @NSManaged var localFileUrl: URL
    @NSManaged var nextAttemptDate: Date?
    @NSManaged var number: Int16
    @NSManaged var status: String
    @NSManaged var streamId: UUID

    // MARK: - CoreDataQueryable

    static var idAttribute: Attribute<ID> {
        Attribute(\StreamPartManagedObject.id)
    }
}
