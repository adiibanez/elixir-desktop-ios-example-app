import SwiftUI
import os

@main
struct TodoApp: App {
    private let logger = Logger(subsystem: "TodoApp", category: "UI");
    @Environment(\.scenePhase) var scenePhase
    
    var bridge: ()? = Bridge.instance?.reinit();/* {
        bridge.reinit()
    }*/
    
    var content = ContentView()
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
                /*if let bridge = Bridge.instance {
                    bridge.reinit()
                }*/
            default: break
            }
        }

    }
}
