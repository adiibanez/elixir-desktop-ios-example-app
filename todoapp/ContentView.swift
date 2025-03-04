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
    @State private var bridgeStatus: BridgeState = .unknown
    //@ObservedObject var bridge = Bridge.instance!
    //@StateObject var bridge: Bridge? = Bridge.instance
    //@State private var bridgeInstance: Bridge? = Bridge.instance
    //@ObservedObject var bridge: Bridge
    
    
    var body: some View {
        VStack {
            switch bridgeStatus {
            case .unknown:
                VStack{
                    statusUIText
                    setupUI
                }
            case .stopped:
                statusUIText
                setupUI
            case .starting:
                ProgressView("Starting Bridge...")
                    .padding()
                
            case .running:
                statusUIText
            case .failed(let error):
                VStack {
                    statusUIText
                    Button("Retry Setup") {
                        
                        Task {
                            do {
                                try Bridge.instance?.setup() // Allow retry on failure
                            } catch {
                                print("Error during setup: \(error)")
                                /*await MainActor.run { bridgeStatus = .failed(error as? ErlangError ?? .unknownError) } */
                            }
                        }
                        
                    }
                    //.buttonStyle(.borderedProminent)
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
        //.ignoresSafeArea(edges: .top)
        .onAppear {
            DispatchQueue.main.async {
                let bridge = try! Bridge()
                self.webview = WebViewController()
                self.webview?.webview.onFinish {
                    self.isActive = true
                }
                bridge.setWebView(view: self.webview!)
            }
        }
    }
    
    func bridgeStateColor(_ state: BridgeState) -> Color {
        switch state {
        case .failed(_):
            return .red  // 🔴 Error state
        case .running:
            return .green  // ✅ Running
        case .starting:
            return .orange  // 🟠 Starting
        default:
            return .gray  // ⚪ Default (idle)
        }
    }
    
    func bridgeStateMessage(_ state: BridgeState) -> String {
        switch state {
        case .starting:
            return "Starting..."
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
        Text(statusText).onChange(of:  Bridge.instance?.state) { newValue in
            statusText = "Bridge Status: \(bridgeStateMessage(newValue ?? .unknown))"
            statusColor = bridgeStateColor(newValue ?? .unknown)
        }.foregroundColor(statusColor)
            .padding()
        
    }
    private var setupUI: some View {
        VStack { // Group views if you need multiple views in a case
            Text("Bridge is Stopped")
                .padding()
            Button("Start") {
                // Action for "Start" button when state is .stopped
                Task {
                    do {
                        try Bridge.instance?.setup()
                    } catch {
                        print("Error during setup: \(error)")
                        /*await MainActor.run { bridgeStatus = .failed(error as? ErlangError ?? .unknownError) } */
                    }
                }}
            .padding()
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Preview ...")
        //ContentView()
    }
}
