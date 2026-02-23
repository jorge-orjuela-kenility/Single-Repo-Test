//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

/// Creates a predicate function that evaluates whether the value at a given
/// `KeyPath` equals a specific value.
///
/// This operator allows you to express comparisons in a declarative, composable
/// way such as:
///
///     let isRunning = \StreamModel.status == .running
///     let filtered = streams.filter(isRunning)
///
/// - Parameters:
///   - lhs: A key path referencing a `Value` on a given `Root` type.
///   - rhs: A value to compare against the property referenced by the key path.
/// - Returns: A closure `(Root) -> Bool` that returns `true` when the evaluated
///            instance's property matches `rhs`.
public func == <Root, Value: Equatable>(lhs: KeyPath<Root, Value>, rhs: Value) -> (Root) -> Bool {
    { root in root[keyPath: lhs] == rhs }
}

/// Creates a predicate function that checks whether the value at a given
/// `KeyPath` exists within a collection of allowed values.
///
/// This operator is useful for building membership filters declaratively:
///
///     let acceptable = [ .running, .ready ]
///     let isAcceptable = \StreamModel.status << acceptable
///     let filtered = streams.filter(isAcceptable)
///
/// - Parameters:
///   - lhs: A key path referencing a `Value` on `Root`.
///   - rhs: A collection of acceptable values.
/// - Returns: A closure `(Root) -> Bool` that evaluates to `true` when the
///            instance's property is contained in `rhs`.
public func << <Root, Value: Equatable>(lhs: KeyPath<Root, Value>, rhs: [Value]) -> (Root) -> Bool {
    { root in rhs.contains(root[keyPath: lhs]) }
}

/// Creates a predicate function that checks whether the value at a given
/// `KeyPath` is greater than or equal to a provided comparison value.
///
/// This operator is useful for building declarative numeric or comparable
/// filters. For example:
///
///     let isLongVideo = \Video.duration >= 600
///     let longVideos = videos.filter(isLongVideo)
///
/// - Parameters:
///   - lhs: A key path referencing a `Value` on `Root` that conforms to `Comparable`.
///   - rhs: A value to compare against.
/// - Returns: A closure `(Root) -> Bool` that evaluates to `true` when the
///            instance's property is greater than or equal to `rhs`.
public func >= <Root, Value: Comparable>(lhs: KeyPath<Root, Value>, rhs: Value) -> (Root) -> Bool {
    { root in root[keyPath: lhs] >= rhs }
}

/// Creates a predicate that checks inequality between a property and a value.
///
/// This operator allows you to build expressive predicate conditions using
/// key paths:
///
///     let isNotRunning = \StreamModel.status != .running
///     let filtered = streams.filter(isNotRunning)
///
/// The resulting closure evaluates the property referenced by the key path
/// on a given `Root` instance and returns `true` only when it differs from
/// the specified value.
///
/// - Parameters:
///   - lhs: A key path to an `Equatable` property on `Root`.
///   - rhs: A value to compare against the property referenced by `lhs`.
/// - Returns: A predicate `(Root) -> Bool` that evaluates to `true` when
///            `root[keyPath: lhs]` is not equal to `rhs`.
public func != <Root, Value: Equatable>(lhs: KeyPath<Root, Value>, rhs: Value) -> (Root) -> Bool {
    { root in root[keyPath: lhs] != rhs }
}

/// Combines two predicate functions using logical AND.
///
/// This operator allows you to build rich predicate expressions:
///
///     let isRunning = \StreamModel.status == .running
///     let hasAttempts = \StreamModel.attempts << [0, 1, 2]
///     let predicate = isRunning && hasAttempts
///
///     let filtered = streams.filter(predicate)
///
/// - Parameters:
///   - lhs: A predicate function `(Root) -> Bool`.
///   - rhs: A predicate function `(Root) -> Bool`.
/// - Returns: A closure `(Root) -> Bool` that evaluates both predicates and
///            returns `true` only if both are satisfied.
public func && <Root>(lhs: @escaping (Root) -> Bool, rhs: @escaping (Root) -> Bool) -> (Root) -> Bool {
    { root in lhs(root) && rhs(root) }
}

/// Combines two predicate functions using logical OR.
///
/// Useful for cases where a model should match either of multiple conditions:
///
///     let isRunning = \StreamModel.status == .running
///     let isReady = \StreamModel.status == .ready
///     let predicate = isRunning || isReady
///
///     let filtered = streams.filter(predicate)
///
/// - Parameters:
///   - lhs: A predicate function `(Root) -> Bool`.
///   - rhs: A predicate function `(Root) -> Bool`.
/// - Returns: A closure `(Root) -> Bool` that evaluates to `true` when either
///            predicate is satisfied.
public func || <Root>(lhs: @escaping (Root) -> Bool, rhs: @escaping (Root) -> Bool) -> (Root) -> Bool {
    { root in lhs(root) || rhs(root) }
}
