// ValueDispatcher.swift
// find.a.BLE

import Foundation

class ValueDispatcher<T> {
    var continuation: AsyncStream<T>.Continuation? = nil

    func next(value: T) {
        continuation?.yield(value)
    }

    func getValueStream(hotSignal: Bool = false) -> AsyncStream<T> {
        .init(T.self, bufferingPolicy: hotSignal ? .bufferingNewest(1) : .unbounded) { continuation in
            self.continuation = continuation
            continuation.onTermination = { _ in
                self.continuation = nil
            }
        }
    }
}
