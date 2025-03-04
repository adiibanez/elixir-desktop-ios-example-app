import SwiftUI
import UIKit
import WebKit
import os

struct ContentView: View {
    private let logger = Logger(subsystem: "ContentView", category: "UI");
    
    @State var isActive : Bool = false
    @State var webview : WebViewController?
    @State private var statusText: String = "..."
    @State private var statusColor: Color = .gray
    
    @ObservedObject var bridge: Bridge = Bridge.shared
    
    var body: some View {
        VStack {
            if (
                bridge.state == .stopped ||
                bridge.state == .unknown ||
                bridge.state == .running) {
                statusUIText
                setupUI
            } else if (bridge.state == .setup) {
                ProgressView("Setting up...")
                    .padding()
            } else if (bridge.state == .starting) {
                ProgressView("Starting Bridge...")
                    .padding()
            } else if case .failed(let error) = bridge.state { // Handle the .failed case
                VStack {
                    statusUIText
                    Text("Error: \(error.localizedDescription)")  // Display the error message
                        .foregroundColor(.red)
                        .padding()
                    
                    Button("Retry Setup") {
                        Task {
                            try bridge.setup()
                        }
                    }
                    .padding()
                }
            }
            
            Spacer()
            
            if self.isActive {
                if let webview = self.webview {
                    webview.ignoresSafeArea()
                } else {
                    Text("Loading WebView...")
                        .foregroundColor(.gray)
                }
            } else {
                ZStack {
                    Color(red: 47/255, green: 36/255, blue: 58/255)
                        .ignoresSafeArea()
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                self.webview = WebViewController()
                self.webview?.webview.onFinish {
                    self.isActive = true
                }
                Bridge.shared.setWebView(view: self.webview!)
            }
        }
    }
    
    func bridgeStateColor(_ state: BridgeState) -> Color {
        switch state {
        case .failed(_):
            return .red
        case .running:
            return .green
        case .starting:
            return .orange
        case .setup:
            return .blue
        default:
            return .gray
        }
    }
    
    func bridgeStateMessage(_ state: BridgeState) -> String {
        switch state {
        case .starting:
            return "Starting...🟠"
        case .setup:
            return "Setup ... ☑️"
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


extension ContentView {
    private var statusUIText: some View {
        Text("Bridge Status: \(bridgeStateMessage(bridge.state))")
            .foregroundColor(bridgeStateColor(bridge.state))
            .padding()
            .onChange(of: bridge.state) { newValue in
                print("Bridge state changed to: \(newValue)") // Log for debugging
                statusText = "Bridge Status: \(bridgeStateMessage(newValue))"
                statusColor = bridgeStateColor(newValue)
            }
        
    }
    private var setupUI: some View {
        VStack {
            if (bridge.state == .stopped || bridge.state == .unknown) {
                Button("Start") {
                    Task {
                        try bridge.setup()
                    }}
                .padding()
            } else if (bridge.state == .running) {
                Button("Reinit") {
                    Task {
                        bridge.reinit()
                    }}
                .padding()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Preview ...")
        //ContentView()
    }
}
