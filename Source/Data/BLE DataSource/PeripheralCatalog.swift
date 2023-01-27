// PeripheralCatalog.swift
// find.a.BLE

import CoreBluetooth

/// This actor is needed to hold onto a reference for a peripheral so the retain count stays positive.
actor PeripheralCatalog {
    private var catalog = [String: CBPeripheral]()

    func lookup(id: String) -> CBPeripheral? {
        catalog[id]
    }

    func add(peripheral: CBPeripheral) {
        catalog[peripheral.identifier.uuidString] = peripheral
    }

    func remove(id: String) {
        catalog[id] = nil
    }
}
