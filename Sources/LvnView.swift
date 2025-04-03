import SwiftUI
import os
import LiveViewNative

struct LvnView: View {
    
    private let logger = Logger(subsystem: "LvnView", category: "UI");
    //@ObservedObject var bridge: Bridge = Bridge.shared
    
    @State private var url: URL = URL(string: "https://example.com")!
    @ObservedObject var bridge: Bridge = Bridge.shared
    @State private var lastURL = nil as URL?
    
    let lvnSingleton: LvnSocketSingleton = LvnSocketSingleton()
    
    var body: some View {
        
            
            Group{
                if(lastURL != nil ) {
                    #LiveView(
                        .automatic(
                            //development: .localhost(port: 4010, path: "/"),
                            //development: .localhost(port: 10000, path: "/lvn"),
                            development: Bridge.shared.lastURL! as URL,
                            production: Bridge.shared.lastURL! as URL // URL(string: "https://example.com")!
                        ),
                        addons: [
                            .ble
                        ]
                    ) {
                        ConnectingView()
                    } disconnected: {
                        DisconnectedView()
                    } reconnecting: { content, isReconnecting in
                        ReconnectingView(isReconnecting: isReconnecting) {
                            content
                        }
                    } error: { error in
                        ErrorView(error: error)
                    }.onAppear {
                        print("LvnView appeared ...")
                        
                    }
                } else {
                    Text("No URL available yet")
                }
            }.onReceive(bridge.urlAvailableEvent) { newUrl in
                
                logger.debug("Received urlAvailableEvent")
                
                guard let reconnectURL = newUrl else { return }
                logger.debug("urlAvailableEvent \(reconnectURL)")
                Task {
                    await LvnSocketSingleton.shared.session?.reconnect(url: reconnectURL)
                }
                
                lastURL = newUrl
            }
        }
    
}
