// AdvertisedDevice.swift
// find.a.BLE

import Foundation

struct AdvertisedDevice: Identifiable, Equatable {
    let id: String
    var deviceName: String
    var manufacturer: String
    var model: String
    var isHidden: Bool
    var rssi: Int
    var lastPing: Double
}

extension AdvertisedDevice {
    func getExportName() -> String {
        guard deviceName.isEmpty else { return deviceName }
        return [model, manufacturer].filter { !$0.isEmpty }.joined(separator: " | ")
    }
}
