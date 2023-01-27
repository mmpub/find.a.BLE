import Foundation
import CoreBluetooth
import MVVM_D

public enum BLEInterrogationFail: Codable {
    case timeout
    case cannotConnect
}

public enum BLEInterrogationResult: Codable {
    case success(String, String, String)
    case fail(BLEInterrogationFail)
}


typealias StartInterrogationCallback = ()->()
typealias CancelInterrogationCallback = ()->()

internal final class BLEPeripheralDAO: MVVMD_DataAccessObject {
    var continuation: AsyncStream<Data>.Continuation? = nil
    var startInterrogation: StartInterrogationCallback = {}
    var cancelInterrogation: CancelInterrogationCallback = {}
    var watchdogTimerTask: Task<Void,Error>!

    func setCallbacks(startInterrogation: @escaping StartInterrogationCallback, cancelInterrogation: @escaping CancelInterrogationCallback) {
        self.startInterrogation = startInterrogation
        self.cancelInterrogation = cancelInterrogation
    }

    public func getDataStream() -> AsyncStream<Data> {
        .init { continuation in
            self.continuation = continuation

            continuation.onTermination = { _ in
                self.continuation = nil
            }

            watchdogTimerTask = Task {
                try await Task.sleep(nanoseconds: 15 * 1_000_000_000)
                cancelInterrogation()
                onReceive(result: .fail(.timeout))
            }

            startInterrogation()
        }
    }

    func onReceive(data: Data) {
        watchdogTimerTask.cancel()
        continuation?.yield(data)
    }

    func onReceive(result: BLEInterrogationResult) {
        do {
            let encoded = try JSONEncoder().encode(result)
            onReceive(data: encoded)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
