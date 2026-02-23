//
// Copyright © 2026 TruVideo. All rights reserved.
//

import CoreData
import CoreDataUtilities
import Foundation
import TruVideoFoundation

@testable import TruVideoMediaUpload

/// An in-memory mock implementation of the `Database` protocol intended for unit testing.
///
/// `DatabaseMock` simulates basic persistence behavior by storing models in memory.
/// It allows tests to verify database interactions without relying on Core Data
/// or any external persistence layer.
///
/// The mock supports:
/// - Saving single or multiple models
/// - Retrieving models by type and predicate
/// - Finding a model by identifier
/// - Injecting errors to simulate database failures
///
/// This type is implemented as an `actor` to match the concurrency guarantees
/// of the real database implementation.
public final actor DatabaseMock: Database {
    // MARK: - Public Properties

    /// Internal in-memory storage keyed by a string identifier.
    private var storage: [String: any Model] = [:]

    /// An optional error to simulate failures when writing or removing files.
    public var error: UtilityError?

    // MARK: - Private Properties

    /// Stores active `AsyncStream` continuations keyed by model type.
    private var continuations: [ObjectIdentifier: Any] = [:]

    // MARK: - Initializer

    /// Creates an instance of the `Database`.
    public init() {}

    // MARK: - Database

    /// Finds and returns a model of the specified type with the given identifier.
    ///
    /// - Parameters:
    ///   - type: The expected model type.
    ///   - id: The identifier of the model to retrieve.
    ///
    /// - Returns: The model matching the given identifier.
    public func find<T: Model>(_ type: T.Type, with id: T.ID) async throws(UtilityError) -> T {
        if let error {
            throw error
        }

        guard let model = storage[String(describing: id)] as? T else {
            throw UtilityError(kind: .DatabaseError.findFailed)
        }

        return model
    }

    /// Observes changes for a given model type matching a predicate.
    ///
    /// This mock implementation does not track live changes.
    /// It immediately emits an empty array and then finishes.
    ///
    /// This behavior is sufficient for tests that only require
    /// the observation pipeline to exist.
    ///
    /// - Parameters:
    ///   - type: The model type to observe.
    ///   - predicate: A predicate describing which models to observe.
    ///
    /// - Returns: An `AsyncStream` that emits a single empty value and completes.
    public func observeChanges<T: Model>(
        of type: T.Type,
        where predicate: NSPredicate
    ) async -> AsyncStream<[T]> {
        let key = ObjectIdentifier(type)

        return AsyncStream { continuation in
            continuations[key] = continuation

            let initial: [T] = storage.values.compactMap { $0 as? T }
            continuation.yield(initial)
        }
    }

    /// Retrieves all stored models of the specified type matching a predicate.
    ///
    /// The predicate is currently ignored and all stored models
    /// of the requested type are returned.
    ///
    /// - Parameters:
    ///   - type: The model type to retrieve.
    ///   - predicate: A predicate used to filter results (not applied in this mock).
    ///
    /// - Returns: An array of models of the requested type.
    ///
    /// - Throws: The injected `UtilityError` if `error` is set.
    public func retrieve<T: Model>(of type: T.Type, where predicate: NSPredicate) throws(UtilityError) -> [T] {
        if let error {
            throw error
        }

        return storage.values.compactMap { $0 as? T }
    }

    /// Saves an array of models into the in-memory storage.
    ///
    /// Existing models with the same storage key will be overwritten.
    ///
    /// - Parameter models: The models to persist.
    ///
    /// - Throws: The injected `UtilityError` if `error` is set.
    public func save(_ models: [some Model]) async throws(UtilityError) {
        if let error { throw error }

        for model in models {
            storage[String(describing: model.id)] = model
        }

        if let first = models.first {
            notifyObservers(of: type(of: first))
        }
    }

    /// Saves a single model into the in-memory storage.
    ///
    /// If a model with the same storage key already exists,
    /// it will be replaced.
    ///
    /// - Parameter model: The model to persist.
    ///
    /// - Throws: The injected `UtilityError` if `error` is set.
    public func save(_ model: some Model) async throws(UtilityError) {
        if let error { throw error }

        storage[String(describing: model.id)] = model

        notifyObservers(of: type(of: model))
    }

    // MARK: - Helper Method

    /// Sets or clears the error to be injected by the mock database.
    ///
    /// This allows tests to simulate failure scenarios by configuring
    /// the `DatabaseMock` to throw a specific `UtilityError` when
    /// `save`, `find`, or `retrieve` methods are called.
    ///
    /// - Parameter error: The `UtilityError` to inject, or `nil` to clear any existing error.
    public func setError(_ error: UtilityError?) async {
        self.error = error
    }

    // MARK: - Private method

    private func notifyObservers<T: Model>(of type: T.Type) {
        let key = ObjectIdentifier(type)

        guard let continuation = continuations[key]
            as? AsyncStream<[T]>.Continuation else {
            return
        }

        let models = storage.values.compactMap { $0 as? T }
        continuation.yield(models)
    }
}
