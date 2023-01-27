import Foundation
import CoreBluetooth
import SingleInstance
import MVVM_D

public struct BLEScannerResult: Codable {
    let uuid: String
    let name: String
    let signal: String
    let date: String
}


typealias ScanActionCallback = ()->()

final class BLEScannerDAO: SingleInstance, MVVMD_DataAccessObject {
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
