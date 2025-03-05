import SwiftUI
import UIKit
import WebKit
import os

struct ContentView: View {
    private let logger = Logger(subsystem: "ContentView", category: "UI");
    
    @State var webviewIsActive : Bool = false
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
            
            if bridge.state == .running && webviewIsActive {
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
                    self.webviewIsActive = true
                }
                Bridge.shared.setWebView(view: self.webview!)
            }
        }.onChange(of: bridge.state) { newState in
            if newState == .running {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if let webview = self.webview {
                        webview.loadURL(url: bridge.lastURL!)
                    } else {
                        logger.error( "Could not load URL, no webview available")
                    }
                }
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
