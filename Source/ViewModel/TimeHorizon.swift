// TimeHorizon.swift
// find.a.BLE

import Foundation

enum TimeHorizon: Double, CaseIterable, Identifiable {
    var id: String  { UUID().uuidString }

    case fiveSeconds    = 5.0
    case fifteenSeconds = 15.0
    case thirtySeconds  = 30.0
    case forever        = 1_000_000.0

    var label: String {
        self == .forever ? "None" : "\(Int(self.rawValue)) seconds"
    }
}
