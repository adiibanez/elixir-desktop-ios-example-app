import SwiftUI
import os

@main
struct TodoApp: App {
    
#if os(watchOS)
    //@WKApplicationDelegateAdaptor var appDelegate: WatchOSAppDelegate
#elseif os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate
#elseif os(macOS)
    //@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate
#endif
    
    init() {
        
        /*DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let appZip = Bundle.main.url(forResource: "app", withExtension: "zip")
            print("TodoApp init: \(String(describing: appZip))")
        }*/
        
        /*if let appZipURL = Bundle.main.url(forResource: "app", withExtension: "zip") {
            
            print("TodoApp init() App ZIP URL found: \(appZipURL)")
            
            Task {
                try Bridge.shared.unpackApp();
            }
            
            // You can now reliably use appZipURL here
            // e.g., pass it to your Bridge for setup
        } else {
            print("Error: app.zip NOT found in bundle!")
        }*/
    }
    
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
    
    //@State private var selectedTab: Int = 0
    @AppStorage("selectedTabViewTab") private var selectedTab: Int = 0
    
    var body: some View {
        VStack {
            BridgeView()
            //.frame(height: 100, alignment: Alignment.topLeading)
            TabView(selection: $selectedTab) {
                // First Tab
                ContentView()
                    .tabItem {
                        Label("Webview", systemImage: "house.fill")
                    }.tag(0)
                // Second Tab
                LvnView()
                    .tabItem {
                        Label("LVN", systemImage: "bolt.fill")
                    }.tag(1)
            }
        }.onAppear(){
            //loadSelectedTab()
            Task {
                
                /*DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                 let appZip = Bundle.main.url(forResource: "app", withExtension: "zip")
                 print("TodoApp onAppear: \(String(describing: appZip))")
                 
                 }*/
                
                //try Bridge.shared.unpackApp();
                try Bridge.shared.setup();
            }
        }.onChange(of: selectedTab) { oldTab, newTab in
            saveSelectedTab(newTab)
        }
    }
    
    // UserDefaults key for storing the selected tab
        private let selectedTabKey = "selectedTabViewTab"

        // Function to save the selected tab index to UserDefaults
        private func saveSelectedTab(_ tabIndex: Int) {
            UserDefaults.standard.set(tabIndex, forKey: selectedTabKey)
        }

        // Function to load the selected tab index from UserDefaults
        private func loadSelectedTab() {
            if let savedTab = UserDefaults.standard.value(forKey: selectedTabKey) as? Int {
                selectedTab = savedTab
            }
            // If no saved tab index is found, it defaults to 0 (set in @State declaration)
        }
}
