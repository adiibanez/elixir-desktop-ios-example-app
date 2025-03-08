import SwiftUI
import LiveViewNative
import LiveViewNativeCore

class AuthTokenHelper {
    
    /*func connect() -> LiveViewNativeCore.Socket {
        let timeout: TimeInterval = 2

        Task {
            do {
                socket = try await self.socket?.connect(timeout: .distantFuture)
                print("Connected!")
            } catch {
                print("Error connecting: \(error)")
            }
        }
        return socket
    }*/
    

    
    static func sendGetTokenToPhoenix(token: String) {
        // Construct the GET URL
        
        
        
        
        
        //https://localhost:4001/auth/user/magic_link/?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhY3QiOiJzaWduX2luX3dpdGhfbWFnaWNfbGluayIsImF1ZCI6In4-IDQuNCIsImV4cCI6MTczOTM2MDM4OCwiaWF0IjoxNzM5MzU5Nzg4LCJpZGVudGl0eSI6ImFkaS5pYmFuZXpAZnJlZXN0eWxlYWlyLmNvbSIsImlzcyI6IkFzaEF1dGhlbnRpY2F0aW9uIHY0LjQuOCIsImp0aSI6IjMwaG41MHBoazEwczJqb2I2czAwMDdkMSIsIm5iZiI6MTczOTM1OTc4OCwic3ViIjoidXNlciJ9.HBPrHGWPG9ew_MB-0mJ7F3Bm-mm3YF2asY5njswjTHA
        
        guard let encodedToken = token.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("Error: Could not URL encode token")
            return
        }
        
        // &redirect_uri=/lvn
        guard let phoenixAuthURL = URL(string: "http://localhost:4000/auth/user/magic_link?redirect_uri=/lvn-auth-check&_format=swiftui&token=\(encodedToken)") else {
            print("Error: Invalid URL")
            return
        }
        
        // Create the request
        var request = URLRequest(url: phoenixAuthURL)
        request.httpMethod = "GET" // Change method to GET
        
        // Configure cookie sharing (if applicable)
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.httpCookieAcceptPolicy = .always
        sessionConfiguration.httpShouldSetCookies = true
        
        let session = URLSession(configuration: sessionConfiguration)
        
        // Create the data task
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching from Phoenix: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Server response status code: \(httpResponse.statusCode)")
                
                // Check for cookies in the response and print
                if let headerFields = httpResponse.allHeaderFields as? [String: String],
                   let URL = httpResponse.url {
                    let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: URL)
                    for cookie in cookies {
                        print("Received cookie: \(cookie)")
                        //Store cookie, after logging on to the webpage
                    }
                }
            }
            
            // Handle the response from Phoenix
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Phoenix response: \(responseString)")
                // Optionally, store the auth token or user data received from Phoenix
            }
        }
        
        // Start the task
        task.resume()
    }
    
    static func postTokenToPhoenix(token: String) { // Shared implementation
        let phoenixAuthURL = URL(string: "/lvn-auth")! // Ensure valid URL
        
        var request = URLRequest(url: phoenixAuthURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["token": token]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error posting token to Phoenix: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Server response status code: \(httpResponse.statusCode)")
            }
            // Handle the response from Phoenix
            if let data = data, let string = String(data: data, encoding: .utf8) {
                print("Phoenix response: \(string)")
                // Optionally, store the auth token or user data received from Phoenix
            }
        }
        task.resume()
    }
    
    static func extractTokenFromURL(url: URL) -> String {
        let urlString = url.absoluteString
        
        // Define the regex pattern to match the token.  Customize this!
        let pattern = "sensocto://token=(.*)"  // Capture everything after "sensocto://token="
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: urlString.utf16.count)
            
            if let match = regex.firstMatch(in: urlString, options: [], range: range) {
                // Get the captured group (the token)
                let tokenRange = match.range(at: 1) // Group 1 is the first capture group
                if let swiftRange = Range(tokenRange, in: urlString) {
                    let token = String(urlString[swiftRange])
                    print("Extracted token: \(token)")
                    
                    // Now you have the token, send it to your Phoenix server
                    return token
                } else {
                    print("Error: Could not convert NSRange to Range")
                }
            } else {
                print("No match found in URL: \(urlString)")
            }
        } catch {
            print("Error creating regex: \(error)")
        }
        return ""
    }
    
    
}
