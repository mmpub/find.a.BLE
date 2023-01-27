import Foundation
import SwiftUI

fileprivate var barsImageName = "wifi"
fileprivate var hideIconName = "eye.slash"
fileprivate var unhideIconName = "eye.slash.fill"

struct ScanResultCell: View {
    @Binding var isScanning: Bool
    var hideAction: @MainActor ()->()
    let name: String
    let manufacturer: String
    let model: String
    let id: String
    let isHidden: Bool
    let signal: String
    let showGraphic: Bool
    let lastPing: Double

    var body: some View {
        if !name.isEmpty {
            HStack {
                if !isScanning {
                    Button{ Task { @MainActor in hideAction() }} label: {
                        Image(systemName: isHidden ? unhideIconName : hideIconName)
                    }
                }
                VStack(alignment: .leading) {
                    Text(name)
                        .font(.headline)
                        .padding(.top, 1)
                    Text(id)
                        .font(.system(size: 8.0))
                        .foregroundColor(.gray)
                }
                Spacer()
                if !isHidden {
                    if showGraphic {
                        Image(systemName: barsImageName, variableValue:  Double(signal)! * 0.01)
                    } else {
                        Text(signal)
                            .font(.system(size: 14.0))
                            .foregroundColor(.gray)
                            .padding(.bottom, 1.0)
                    }
                }
            }
            .padding([.bottom, .top], 1)
        } else {
            HStack {
                if !isScanning {
                    Button{ Task { @MainActor in hideAction() }} label: {
                        Image(systemName: isHidden ? unhideIconName : hideIconName)
                    }
                }
                VStack(alignment: .leading) {
                    Text(id)
                        .font(.system(size: 12.0))
                        .foregroundColor(.gray)
                    if !manufacturer.isEmpty || !model.isEmpty {
                        Text([model, manufacturer].filter { !$0.isEmpty }.joined(separator: " | "))
                            .font(.system(size: 11.0))
                    }
                }
                Spacer()
                if !isHidden {
                    if showGraphic {
                        Image(systemName: barsImageName, variableValue: Double(signal)! * 0.01)
                    } else {
                        Text(signal)
                            .font(.system(size: 12.0))
                            .foregroundColor(.gray)
                            .padding(.bottom, 1.0)
                    }
                }
            }
        }
    }
}

