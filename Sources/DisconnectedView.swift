//
//  DisconnectedView.swift
//  DisconnectedView
//

import SwiftUI
import os

struct DisconnectedView: View {
    private let logger = Logger(subsystem: "DisconnectedView", category: "UI");
    @ObservedObject var bridge: Bridge = Bridge.shared
    
    var body: some View {
        if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
            ContentUnavailableView {
                Label("No Connection", systemImage: "network.slash")
            } description: {
                Text("The app will reconnect when network connection is regained.")
            }
        } else {
            VStack {
                Label("No Connection", systemImage: "network.slash")
                    .font(.headline)
                Text("The app will reconnect when network connection is regained.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    DisconnectedView()
}
