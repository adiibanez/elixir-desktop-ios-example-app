//
//  WebViewRepresentable.swift
//
//  Created by Dominic Letz on 19.09.22
//

import Foundation
import Combine
import SwiftUI
import WebKit

struct WebViewRepresentable: View {
    var lastURL: URL?
    @EnvironmentObject var viewModel: WebViewViewModel  // Get from environment

    init(url: URL? = nil) {
        self.lastURL = url
      //  self.viewModel = WebViewViewModel() // NO LONGER NEEDED - get from Environment
    }

    var body: some View {
        #if os(macOS)
        WebViewRepresentableMac(lastURL: lastURL)
        #else
        WebViewRepresentableIOS(lastURL: lastURL)
        #endif
    }
}



// MARK: - iOS Implementation

#if os(iOS)
struct WebViewRepresentableIOS: UIViewRepresentable {
    @EnvironmentObject var viewModel: WebViewViewModel // Get from environment
    var lastURL: URL?

    func makeUIView(context: Context) -> WKWebView {
        print("makeUIView (iOS)")
        return viewModel.webview // Return the ALREADY initialized webview
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        print("updateUIView (iOS)")
        //No longer needed to load here, only on reception from the bridge
    }
}
#endif

// MARK: - macOS Implementation

#if os(macOS)
struct WebViewRepresentableMac: NSViewRepresentable {
    @EnvironmentObject var viewModel: WebViewViewModel  // Get from environment
    var lastURL: URL?

    func makeNSView(context: Context) -> WKWebView {
        print("makeNSView (macOS)")
        return viewModel.webview  // Return the ALREADY initialized webview
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        print("updateNSView (macOS)")
         //No longer needed to load here, only on reception from the bridge
    }
}
#endif
final class WebViewViewModel: NSObject, ObservableObject, WKNavigationDelegate, WKScriptMessageHandler {
    var webview: WKWebView!  // Made optional, then implicitly unwrapped
    var finish: (() -> ())?
    @Published var shouldLoadURL: Bool = true

      override init() { // Setup is now done on demand.
        super.init()
        setupWebView()
      }

    func setupWebView() { // Setup is now done on demand.
        guard webview == nil else { return } // IMPORTANT: Only set up ONCE

      // Enable javascript in WKWebView to interact with the web app
        let preferences = WKPreferences()
        let page = WKWebpagePreferences()
        page.allowsContentJavaScript = true

        let configuration = WKWebViewConfiguration()
        configuration.limitsNavigationsToAppBoundDomains = true
        configuration.preferences = preferences
        configuration.defaultWebpagePreferences = page

        webview = WKWebView(frame: .zero, configuration: configuration)
        webview.allowsBackForwardNavigationGestures = true
        #if os(iOS)
          webview.scrollView.isScrollEnabled = true
        #endif

        addScript(configuration, "var meta = document.createElement('meta');" +
            "meta.name = 'viewport';" +
            "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" +
            "var head = document.getElementsByTagName('head')[0];" +
            "head.appendChild(meta);")

        addScript(configuration, "window.onerror = (msg, url, line, column, error) => { " +
          "const message = {" +
          "  message: msg," +
          "  url: url," +
          "  line: line," +
          "  column: column," +
          "  error: JSON.stringify(error)" +
          "}" +
          "if (window.webkit) {" +
          "  window.webkit.messageHandlers.error.postMessage(message);" +
          "}" +
          "};")
        configuration.userContentController.add(self, name: "error")
        addScript(configuration, """
            document.getElementsByTagName('a').forEach(node => {
                node.style.cursor = "pointer";
            })
        """)

        webview.navigationDelegate = self

    }


    func addScript(_ config: WKWebViewConfiguration, _ script: String) {
        let script: WKUserScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.addUserScript(script)
    }

    func onFinish(finish: @escaping () -> ()) {
        self.finish = finish
    }

    func loadURL(url: URL) {
        shouldLoadURL = false // Prevent re-entry during load
        //Make sure the webview is correctly initialized
        guard let webview = webview else {
            print("WebView is nil.  Ensure setupWebView() has been called.")
            return
        }
        webview.load(URLRequest(url: url))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let fun = self.finish {
            fun()
        }
         shouldLoadURL = true // Allow loading again after finishing.
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView failed to load page with error: \(error.localizedDescription)")
        shouldLoadURL = true // Allow loading again after failure
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("WebView didFailProvisionalNavigation with error: \(error.localizedDescription)")
        self.webview.reload()
        shouldLoadURL = true // Allow loading again after failure.

    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "error":
            // You should actually handle the error :)
            let error = (message.body as? [String: Any])?["message"] as? String ?? "unknown"
            assertionFailure("JavaScript error: \(error)")
        default:
            assertionFailure("Received invalid message: \(message.name)")
        }
    }
}
