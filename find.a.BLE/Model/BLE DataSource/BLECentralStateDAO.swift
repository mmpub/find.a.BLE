import Foundation
import CoreBluetooth
import MVVM_D

public enum BLECentralState: String, Codable {
    case uninitialized, poweredOn, poweredOff, resetting, unauthorized, unknown, unsupported

    init(cbManagerState: CBManagerState, authState: BLEAuthorizationState) {
        if authState == .uninitialized {
            self = .uninitialized
        } else {
            switch cbManagerState {
            case .poweredOff:   self = .poweredOff
            case .poweredOn:    self = .poweredOn
            case .resetting:    self = .resetting
            case .unauthorized: self = .unauthorized
            case .unknown:      self = .unknown
            case .unsupported:  self = .unsupported
            @unknown default:   self = .unsupported
            }
        }
    }
}

typealias GetDelegateState = () -> (CBManagerState, BLEAuthorizationState)
typealias OnCentralStateDeinit = () -> Void

internal final class BLECentralStateDAO: MVVMD_DataAccessObject {
    var continuation: AsyncStream<Data>.Continuation? = nil
    var prevStateCallback: GetDelegateState
    var onDeinitCallback: OnCentralStateDeinit!

    init(prevStateCallback: @escaping GetDelegateState) {
        self.prevStateCallback = prevStateCallback
    }
    
    deinit {
        onDeinitCallback?()
    }

    func onDeinit(onDeinitCallback: @escaping OnCentralStateDeinit) {
        self.onDeinitCallback = onDeinitCallback
    }


    public func getDataStream() -> AsyncStream<Data> {
        .init { continuation in
            self.continuation = continuation

            continuation.onTermination = { _ in
                self.continuation = nil
            }
            do {
                let (cbManagerState, authState) = prevStateCallback()
                if let encoded = try? JSONEncoder().encode(BLECentralState(cbManagerState: cbManagerState, authState: authState)) {
                    continuation.yield(encoded)
                }
            }
        }
    }
    
    internal func onReceive(data: Data) {
        continuation?.yield(data)
    }
}
