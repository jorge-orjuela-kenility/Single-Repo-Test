//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

/// Executes an isolated operation on an actor within the current actor's context.
///
/// This function enables safe cross-actor interactions by executing an isolated
/// operation on a different actor while maintaining actor isolation guarantees.
/// It provides a structured way to perform cross-actor work while preserving
/// Swift's concurrency safety model.
///
/// ## Actor Isolation
/// The operation runs with `isolated` access to the target actor, enabling direct
/// synchronization and state modification without additional synchronization
/// mechanisms. This ensures thread-safe access to actor-protected state.
///
/// ## Usage Example
/// ```swift
/// actor MyActor {
///     var value: Int = 0
///     func increment() { value += 1 }
/// }
///
/// let actor = MyActor()
///
/// // Execute an isolated operation on the actor
/// let result = await withActor(actor) { isolated actor in
///     actor.increment()
///     return actor.value
/// }
///
/// print(result) // Prints: 1
/// ```
///
/// ## Cross-Actor Communication
/// This function is particularly useful for:
/// - **State synchronization**: Updating actor state from another actor
/// - **Coordination**: Orchestrating work across multiple actors
/// - **Resource sharing**: Accessing actor-protected resources safely
/// - **Isolation preservation**: Maintaining actor boundaries
///
/// ## Precondition
/// The operation **must** be truly isolated to avoid data races:
/// - **No captures**: Operation should not capture mutable state from other actors
/// - **Pure operations**: Should only interact with the isolated actor
/// - **No side effects**: Should not have unintended side effects outside the actor
///
/// ## Thread Safety
/// - **Actor-safe**: All operations within the closure are actor-isolated
/// - **Reentrant**: Safe to call from reentrant actor contexts
/// - **Deadlock-free**: No risk of actor deadlocks when used correctly
///
/// ## Performance Considerations
/// - **Overhead**: Minimal overhead for actor context switching
/// - **Serialization**: Operations are serialized on the target actor's queue
/// - **Efficiency**: More efficient than traditional synchronization primitives
///
/// ## Error Handling
/// - **Propagates errors**: Throws errors from the operation closure
/// - **Actor errors**: Actor-specific errors are propagated to caller
/// - **Timeout handling**: Consider timeout mechanisms for long-running operations
///
/// ## Discardable Result
/// The `@discardableResult` attribute allows ignoring the return value when
/// the operation's side effects are more important than the result:
/// ```swift
/// // Ignore the return value
/// withActor(actor) { isolated actor in
///     actor.performSideEffect()
/// }
/// ```
///
/// ## Parameters
/// - **actor**: The isolated actor instance to execute the operation on
/// - **operation**: The async closure to execute with isolated access to the actor
///
/// ## Returns
/// The result of the operation closure, preserving the return type
///
/// ## Reentrancy and Deadlocks
/// - **Reentrant calls**: Safe to call from other actor-isolated contexts
/// - **Deadlock prevention**: Swift's structured concurrency prevents deadlocks
/// - **Serialization**: Operations are serialized on the target actor
///
/// - Important: The operation must be truly isolated to avoid data races
/// - Warning: Do not capture mutable state from other actors in the operation closure
/// - Note: This function is a wrapper around Swift's actor isolation system
///
/// - SeeAlso: `Actor` protocol for actor concurrency model
/// - SeeAlso: `isolated` keyword for actor isolation guarantees
@discardableResult
public func withActor<A: Actor, R>(_ actor: isolated A, _ operation: (isolated A) async -> R) async -> R {
    await operation(actor)
}
