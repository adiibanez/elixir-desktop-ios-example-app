//
//  BridgeView.swift
//  SensoctoAppErlang
//
//  Created by Adrian Ibanez on 08.03.2025.
//

import SwiftUI

#if os(watchOS) || os(iOS)
import UIKit
#elseif os(macOS)

#endif
import WebKit
import os
import LiveViewNativeBleClient

struct BridgeView: View {
    let logger = Logger(subsystem: "BridgeView", category: "UI");
    
    @State private var statusText: String = "..."
    @State private var statusColor: Color = .gray
    @State private var bridgeStateMessage:String = "..."
    
    @ObservedObject var bridge: Bridge = Bridge.shared
    
    var body: some View {
        HStack {
            if (
                bridge.state == .stopped ||
                bridge.state == .unknown ||
                bridge.state == .running ||
                bridge.state == .unpacked) {
                statusUIText
                setupUI
            } else if (bridge.state == .unpacking) {
                statusUIText
                ProgressView("Unpacking ...", value: bridge.progress.fractionCompleted)
                    .padding()
            } else if (bridge.state == .starting) {
                statusUIText
                ProgressView("Starting Bridge...", value: bridge.progress.fractionCompleted)
                    .padding()
            } else if case .failed(let error) = bridge.state { // Handle the .failed case
                statusUIText
                setupUI
                Text("Error: \(error.localizedDescription)")  // Display the error message
                    .foregroundColor(.red)
                    .padding()
            }
            Text("Test \(bridge.lastURL?.absoluteString ?? "")")
        }.onChange(of: bridge.state) { oldState, newState in
            DispatchQueue.main.async {
                print("Bridge state changed to: \(newState)") // Debugging log
                statusText = "Bridge Status: \(bridgeStateMessage(newState))"
                statusColor = bridgeStateColor(newState)
            }
        }
        
        /*}.background(
         Color.clear.onAppear {
         updateUI(self.bridge.state)
         }.onChange(of: bridge.state) { newValue in updateUI(newValue) }
         )*/
    }
    
    /*func updateUI(_ state: BridgeState) {
        DispatchQueue.main.async {
            print("Bridge state changed to: \(state)") // Debugging log
            statusText = "Bridge Status: \(bridgeStateMessage(state))"
            statusColor = bridgeStateColor(state)
        }
    }*/
    
    func bridgeStateColor(_ state: BridgeState) -> Color {
        switch state {
        case .failed(_):
            return .red
        case .running:
            return .green
        case .starting:
            return .orange
        case .unpacking:
            return .blue
        default:
            return .gray
        }
    }
    
    func bridgeStateMessage(_ state: BridgeState) -> String {
        switch state {
        case .starting:
            return "Starting... 🟠"
        case .unpacking:
            return "Unpacking... 🟠"
        case .unpacked:
            return "Unpacked ✅"
        case .running:
            return "Running ✅"
        case .stopped:
            return "Stopped ❌"
        case .failed(let error):
            return "Error: \(error.localizedDescription)"
        case .unknown:
            return "Unknown"
        }
    }
}


extension BridgeView {
    private var statusUIText: some View {
        Text("Bridge Status: \(bridgeStateMessage(bridge.state)) P:\(bridge.getBridgePort())")
            .foregroundColor(bridgeStateColor(bridge.state))
            .padding()
        
    }
    private var setupUI: some View {
        Group {
            Button("Test response") {
                Task {
                    do {
                        guard let url = bridge.lastURL else {
                            logger.debug("Test response: no url available")
                            return
                        }
                        
                        logger.debug("Test response: \(bridge.lastURL?.absoluteString ?? "no url")")
                        
                        let urlString = bridge.lastURL!.absoluteString.replacingOccurrences(of: "localhost", with: "127.0.0.1")
                        //let urlString = "http://www.google.com"
                        
                        let (data, response) = try await URLSession.shared.data(from: URL(string: urlString)!)
                        
                        guard let httpResponse = response as? HTTPURLResponse,
                              (200...299).contains(httpResponse.statusCode) else {
                            let responseText = "Server Error: \(String(describing: response))" // Detailed server error
                            logger.debug("Test response: \(responseText)")
                            return
                        }
                        
                        if let stringResponse = String(data: data, encoding: .utf8) {
                            let responseText = stringResponse
                        } else {
                            logger.debug("Test response: Unable to decode response")
                        }
                    } catch {
                        logger.debug("Test response Fetch Error: \(error.localizedDescription)")
                    }
                }
            }
            
            if  (bridge.state == .unknown) {
                Button("Unpack") {
                    Task {
                        try Bridge.shared.unpackApp()
                    }}
                .padding()
            } else if (bridge.state == .stopped ) {
                Button("Start") {
                    Task {
                        try Bridge.shared.setup()
                        Bridge.shared.reinit()
                    }}
                .padding()
            } else if (bridge.state == .unpacked) {
                Button("Setup") {
                    Task {
                        try Bridge.shared.setup()
                    }}
                .padding()
            } else if (bridge.state == .running) {
                Button("Reinit") {
                    Task {
                        Bridge.shared.reinit()
                    }}
                .padding()
            }
        }
    }
}
