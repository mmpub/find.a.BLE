// BLEScannerDAO.swift
// find.a.BLE

import Foundation
import CoreBluetooth
import SingleInstance
import MVVMD

public struct BLEScannerResult: Codable {
    let uuid: String
    let name: String
    let signal: String
    let isConnectable: Bool
}

typealias ScanActionCallback = ()->()

final class BLEScannerDAO: SingleInstance, MVVMD.DataAccessObject {
    private var continuation: AsyncStream<Data>.Continuation? = nil
    private var startScan: ScanActionCallback!
    private var stopScan: ScanActionCallback!

    func onDeinit(callback: ()->()) {}

    func onReceive(data: Data) {
        continuation?.yield(data)
    }

    required init?() {
    }

    func setCallbacks(startScan: @escaping ScanActionCallback, stopScan: @escaping ScanActionCallback) {
        self.startScan = startScan
        self.stopScan = stopScan
    }

    public func getDataStream() -> AsyncStream<Data> {
        .init { continuation in
            self.continuation = continuation

            continuation.onTermination = { _ in
                self.stopScan()
                self.continuation = nil
            }

            startScan()
        }
    }
}
