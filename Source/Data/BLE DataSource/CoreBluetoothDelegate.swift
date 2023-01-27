// CoreBluetoothDelegate.swift
// find.a.BLE

import Foundation
import CoreBluetooth
import CBUUID_Standard

struct InterrogationStrings {
    var deviceName: String? = nil
    var manufacturerName: String? = nil
    var modelName: String? = nil
}

class CBDelegate: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    let queue = DispatchQueue(label: "BLEDataSource")
    var prevState = CBManagerState.poweredOff
    var centralStateDAOList = [BLECentralStateDAO]()
    weak var scannerDAO: BLEScannerDAO? = nil
    private let authPersistKey = "BLEPermissionGranted"
    internal var authState: BLEAuthorizationState {
        get {
            let authState = UserDefaults.standard.string(forKey: authPersistKey)
            return authState == nil ? .uninitialized : .init(rawValue: authState!) ?? .unauthorized
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: authPersistKey)
        }
    }

    func add(centralStateDAO dao: BLECentralStateDAO) {
        centralStateDAOList.append(dao)
    }

    func remove(centralStateDAO dao: BLECentralStateDAO) {
        centralStateDAOList = centralStateDAOList.filter { $0 === dao }
    }

    func set(scannerDAO: BLEScannerDAO) {
        self.scannerDAO = scannerDAO
    }

    func updateStateDAOs(newState: CBManagerState, authState: BLEAuthorizationState) {
        do {
            if let encoded = try? JSONEncoder().encode(BLECentralState(cbManagerState: newState, authState: authState)) {
                centralStateDAOList.forEach { dao in
                    dao.onReceive(data: encoded)
                }
            }
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        prevState = central.state
        authState = central.state == .unauthorized ? .unauthorized : .notunauthorized
        updateStateDAOs(newState: prevState, authState: authState)
    }

    var peripheralCatalog = PeripheralCatalog()
    var interrogationHandler = [String: BLEPeripheralDAO]()
    var interrogationResult = [String: InterrogationStrings]()

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        Task {
            await peripheralCatalog.add(peripheral: peripheral)
            queue.async {
                do {
                    var isConnectable: Bool { (advertisementData["kCBAdvDataIsConnectable"] as? Int) == 1 }
                    if let encoded = try? JSONEncoder().encode(BLEScannerResult(uuid: "\(peripheral.identifier)", name: peripheral.name ?? "", signal: "\(RSSI)", isConnectable: isConnectable)) {
                        self.scannerDAO?.onReceive(data: encoded)
                    }
                }
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([.deviceInformationService])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let dao = interrogationHandler[peripheral.identifier.uuidString] {
            dao.onReceive(result: .fail(.cannotConnect))
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services ?? [] {
            let characteristics: [CBUUID]?
            switch service.uuid {
// Apple OS hides this service.
//            case .deviceName:
//                characteristics = [.deviceName]
            case .deviceInformationService:
                characteristics = [.manufacturerNameString, .modelNumberString]
            default:
                continue
            }
            peripheral.discoverCharacteristics(characteristics, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let id = peripheral.identifier.uuidString
        if interrogationResult[id] != nil {
            for c in service.characteristics ?? [] {
                let name = c.value != nil ? (String(data: c.value!, encoding: .utf8) ?? "") : ""
                switch c.uuid {
// Apple OS hides this service.
//                case .deviceName:
//                    interrogationResult[id]!.deviceName = name
                case .manufacturerNameString:
                    interrogationResult[id]!.manufacturerName = name
                case .modelNumberString:
                    interrogationResult[id]!.modelName = name
                default:
                    break
                }
            }
            let result = interrogationResult[id]!
            if  let manufacturerName = result.manufacturerName,
                let modelName = result.modelName,
                let dao = interrogationHandler[peripheral.identifier.uuidString] {
                dao.onReceive(result: .success(manufacturerName, modelName))
            }
        }
    }
}
