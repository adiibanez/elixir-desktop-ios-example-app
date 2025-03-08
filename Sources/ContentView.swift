import SwiftUI
import UIKit
import WebKit

struct ContentView: View {
    @State private var isActive: Bool = false
    @State private var webview: WebViewController?
    @ObservedObject var bridge: Bridge = .shared
    @State private var urlAvailable: Bool = false
    
    var body: some View {
        VStack {
            if urlAvailable, let webview = webview {
                webview.ignoresSafeArea()
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
                let webController = WebViewController()
                webController.webview.onFinish {
                    DispatchQueue.main.async {
                        self.isActive = true
                    }
                }
                self.webview = webController
            }
        }
        .onReceive(bridge.urlAvailableEvent) { newURL in
            guard let newURL = newURL else { return }
            DispatchQueue.main.async {
                self.urlAvailable = true
                
                if var urlComponents = URLComponents(url: newURL, resolvingAgainstBaseURL: false) {
                    var queryItems = urlComponents.queryItems ?? []
                    queryItems.append(URLQueryItem(name: "_format", value: "html"))
                    urlComponents.queryItems = queryItems

                    if let modifiedURL = urlComponents.url {
                        self.webview?.loadURL(url: modifiedURL)
                    }
                }
                
                //self.webview?.loadURL(url: newURL)
            }
        }
    }
}
