import SwiftUI
import os

@main
struct TodoApp: App {
    
#if os(watchOS)
    //@WKApplicationDelegateAdaptor var appDelegate: WatchOSAppDelegate
#elseif os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate
#elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate
#endif
    
    private let logger = Logger(subsystem: "TodoApp", category: "UI");
    @Environment(\.scenePhase) var scenePhase
    @ObservedObject var bridge: Bridge = .shared
    
    var content = ContentScreen()
    
    var body: some Scene {
        WindowGroup {
            self.content
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                print(".background")
            case .active:
                print(".active")
                Task {
                    logger.log("Reinit bridge")
                    Bridge.shared.reinit()
                }
            default: break
            }
        }
        
    }
}

struct ContentScreen: View {
    var body: some View {
        VStack {
            BridgeView()
                //.frame(height: 100, alignment: Alignment.topLeading)
            TabView {
                // First Tab
                ContentView()
                    .tabItem {
                        Label("Webview", systemImage: "house.fill")
                    }
                // Second Tab
                LvnView()
                    .tabItem {
                        Label("LVN", systemImage: "bolt.fill")
                    }
            }
        }.onAppear(){
            Task {
                try Bridge.shared.unpackApp();
                try Bridge.shared.setup();
            }
        }
    }
}
