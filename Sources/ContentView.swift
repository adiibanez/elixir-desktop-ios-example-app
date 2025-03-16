import SwiftUI
import WebKit
import Combine

struct ContentView: View {
    @State private var isActive: Bool = false
    @StateObject private var webViewModel = WebViewViewModel() // Use StateObject
    @ObservedObject var bridge: Bridge = .shared
    @State private var urlAvailable: Bool = false

    var body: some View {
        VStack {
            if urlAvailable {
                WebViewRepresentable(url: nil) // Pass nil initially, load later
                    .environmentObject(webViewModel) // Inject as EnvironmentObject
                    .ignoresSafeArea()
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
            webViewModel.onFinish {
                DispatchQueue.main.async {
                    self.isActive = true
                }
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
                        self.webViewModel.loadURL(url: modifiedURL) // Load through ViewModel
                    }
                }
            }
        }
    }
}
