//
//  Extensions.swift
//  BluetoothComponents
//
//  Created by Maxim Tarasov on 9/12/25.
//
import Foundation
import Combine

// MARK: - Component Wiring Protocol
public protocol ComponentWiring: AnyObject {
    var cancellables: Set<AnyCancellable> { get set }
}

extension ComponentWiring {
    /// Wire multiple publishers to their destinations in a clean declarative way
    internal func connect(@WiringBuilder _ builder: () -> [AnyCancellable]) {
        let newCancellables = builder()
        for cancellable in newCancellables {
            cancellable.store(in: &cancellables)
        }
    }
}

// MARK: - Component Wiring Base Class (for classes that don't need other inheritance)
public class ComponentWiringBase: ComponentWiring {
    public var cancellables = Set<AnyCancellable>()
}

@resultBuilder
public struct WiringBuilder {
    public static func buildBlock(_ components: AnyCancellable...) -> [AnyCancellable] {
        return components
    }
}

// MARK: - Combine Extensions for Component Wiring
extension Publisher where Failure == Never {
    /// Sends publisher output to a Subject input on a component
    /// Similar to .assign(to:on:) but for Subject inputs instead of @Published properties
    func send<T, S: Subject>(to keyPath: KeyPath<T, S>, on object: T) -> AnyCancellable
    where S.Output == Output {
        return sink { value in
            object[keyPath: keyPath].send(value)
        }
    }

    /// Connects a publisher to a method on an object with weak reference
    /// Similar to .assign(to:on:) but for method calls instead of property assignment
    func call<T: AnyObject>(_ method: @escaping (Output) -> Void, on object: T) -> AnyCancellable {
        return sink { [weak object] value in
            guard object != nil else { return }
            method(value)
        }
    }
}
