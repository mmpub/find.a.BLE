// BLEDataSource

import os.log
import CoreBluetooth
import SingleInstance
import MVVM_D
import CBUUID_Standard

enum BLEAuthorizationState: String {
    case uninitialized, unauthorized, notunauthorized
}

fileprivate class CBDelegate: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
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


    private enum ConstructionState {
        case connecting
        case fetchingServices
        case fetchingCharacteristics
    }

    private enum ScanResultState {
        case constructing(ConstructionState, String, CBPeripheral, Int, Double)
        case active(ScanResult)
        case problem(Error)
        case condemned(ScanResult)
    }

    private var peripherals = [String: CBPeripheral]()

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        let knownPeripherals = self.knownPeripherals
//        do {
//            if let encoded = try? JSONEncoder().encode(BLEScannerResult(uuid: "\(peripheral.identifier)", name: peripheral.name ?? knownPeripherals["\(peripheral.identifier)"] ?? "", signal: "\(RSSI)", date: "2022-11-15 aa:aa:aa")) {
//                if encoded.name.isEmpty {
//                    central.connect(peripheral)
//                } else {
//                    scannerDAO?.onReceive(data: encoded)
//                }
//            }
//        }
        var isConnectable: Bool { (advertisementData["kCBAdvDataIsConnectable"] as? Int) == 1 }
        let id = peripheral.identifier.uuidString
        if peripherals[id] === nil && isConnectable {
//            os_log("Connecting to peripheral \(peripheral.identifier)")
//            for (k,v) in advertisementData {
//                print("Ads \(k) \(v)")
//            }
            peripherals[id] = peripheral
            central.connect(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("connected!")
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID.deviceInformationService])

    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        os_log("failed to connect \(error)")
//        peripherals[peripheral.identifier.uuidString] = nil
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let service = peripheral.services?.first {
            peripheral.discoverCharacteristics([CBUUID.manufacturerNameString, CBUUID.modelNumberString], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        var manufacturerName = ""
        var modelName = ""
        print("-----")
        for c in service.characteristics ?? [] {
            let name = c.value != nil ? (String(data: c.value!, encoding: .utf8) ?? "") : ""
            print("\(c.uuid) \(c.value)")
            if c.uuid == CBUUID.manufacturerNameString {
                manufacturerName = name
            }
            if c.uuid == CBUUID.modelNumberString {
                modelName = name
            }
        }
        print("!! man: \(manufacturerName) mod:\(modelName) \(service.characteristics?.count) !!")
    }
}

public final class BLEDataSource: SingleInstance, MVVMD_DataSource {
    public var params: [String : String] { [:] }

    public var dataSourceID = "BLE"
    private var delegate = CBDelegate()
    private var centralManager: CBCentralManager!
    private static var bluetoothInitialized = false

    public required init?() {
        super.init()
        if delegate.authState != .uninitialized {
            initializeCoreBluetooth()
        }
    }

    func initializeCoreBluetooth() {
        guard !BLEDataSource.bluetoothInitialized else { return }
        centralManager = CBCentralManager(delegate: delegate, queue: delegate.queue)
        Task {
            delegate.updateStateDAOs(newState: .unauthorized, authState: .unauthorized)
        }
        BLEDataSource.bluetoothInitialized = true
    }

    public func createDataAccessObject(id: String, params: [String : String]) -> MVVMD_DataAccessObject? {
        enum DataAccessType: String {
            case initialize
            case centralState
            case scanner
        }

        guard let dataAccessType = DataAccessType(rawValue: id) else { return nil }

        switch dataAccessType {
        case .initialize:
            initializeCoreBluetooth()
            return nil

        case .centralState:
            let dao = BLECentralStateDAO(prevStateCallback: {(self.delegate.prevState,  self.delegate.authState)})
            dao.onDeinit { self.delegate.remove(centralStateDAO: dao) }
            self.delegate.add(centralStateDAO: dao)
            return dao

        case .scanner:
            guard BLEDataSource.bluetoothInitialized, let dao = BLEScannerDAO() else { return nil }
            dao.setCallbacks(
                startScan: { self.centralManager.scanForPeripherals(withServices: nil, options:[CBCentralManagerScanOptionAllowDuplicatesKey:true]) },
                stopScan: { self.centralManager.stopScan() }
            )
            delegate.set(scannerDAO: dao)
            return dao
        }
    }
}

