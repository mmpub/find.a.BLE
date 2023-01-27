import Foundation

enum SignalDisplayFormat: String, CaseIterable, Identifiable {
    var id: String  { UUID().uuidString }
    case bars = "Bars"
    case percent = "Percentage"
    case raw = "dBm"
}

extension Int {
     func format(as rssiFormat: SignalDisplayFormat) -> String {
        let expandedToPercent = 120 + (self * 6 / 5)
        let percent = Swift.max(Swift.min(expandedToPercent, 100), 0)

        switch rssiFormat {
        case .raw:
            return "\(self) dBm"
        case .percent:
            return "\(percent)%"
        case .bars:
            return "\(percent)" // this percentage will be indicated on the SF Symbol variable value
        }
    }
}
