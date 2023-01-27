import Foundation
import Combine
import SingleInstance

class SettingsViewModel: SingleInstance, ObservableObject {
    @Published var signalDisplayFormat: SignalDisplayFormat = .bars
    @Published var timeHorizon: TimeHorizon = .forever
}
