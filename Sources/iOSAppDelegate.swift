
#if os(iOS)

import UIKit
import SwiftUI
import LiveViewNative
import UserNotifications
import LiveViewNativeCore

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    static let lvnHostAndPort: String = "http://192.168.1.193:4000"
    
    static let bridge = Bridge()
    
    static let lvnUrl = URL(string: "\(lvnHostAndPort)/lvn")!
    let session = LiveSessionCoordinator.init(
        lvnUrl
    )
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]?
    ) -> Bool {
        
        Task {
            try Bridge.shared.unpackApp();
        }
        //let appZip = Bundle.main.url(forResource: "app", withExtension: "zip")
        //print("AppDelegate: \(String(describing: appZip))")
        
        /*do {
            try Bridge.shared.unpackApp();
        } catch {
            print("Failed to unpack app: \(error)")
        }*/
        
        /*Task {
            try Bridge.shared.unpackApp();
        }*/
        /*let backgroundService = BackgroundService()
        backgroundService.registerBackgroundTask()
        
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting authorization: \(error)")
            }
            if granted {
                print("Push notifications authorization granted.")
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else {
                print("Push notifications authorization denied.")
            }
        }
        
        Task {
            try await LvnSocketSingleton.shared.join()
        }*/
        
        return true
    }
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert device token to a string
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        
        // Send this token to your server!
        // Your server will use this token to send push notifications to this device.
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    // Called when a notification is delivered to a foreground app.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("Received foreground notification: \(userInfo)")
        // Customize the presentation (e.g., show an alert, play a sound, update the badge)
        
        Task {
            
            print("Push event socket: \(LvnSocketSingleton.shared.getSocket()!.status()) channel: \(LvnSocketSingleton.shared.getChannel()!.status())")
            
            try await LvnSocketSingleton.shared.pushEvent()
        }
        
        
        
        completionHandler([.badge, .sound])
    }
    
    
    // Called when the user taps on a notification (from the notification center or lock screen).
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("Received notification response: \(userInfo)")
        
        // Handle the user's action based on the notification.
        completionHandler()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        print("Received remote notification 1 \(userInfo)")
        Task {
            LvnSocketSingleton.shared.initialize()
            try await LvnSocketSingleton.shared.join()
        }
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any]
    ) async -> UIBackgroundFetchResult {
        print("Received remote notification 2 \(userInfo)")
        
        return .newData
    }
    
    
    
    func application(
        _ app: UIApplication, open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // URL handling code
        print("URL: \(url)")
        
        guard
            let token: String? = AuthTokenHelper.extractTokenFromURL(
                url: url)
        else {
            print("Error parsing URL")
            return true
        }
        //AuthTokenHelper.sendGetTokenToPhoenix(token: token!)
        
        //var authURL: URL! = URL(string: "\(AppDelegate.lvnHostAndPort)/lvn-auth?token=\(token!)")
        let authURL: URL! = URL(string: "\(AppDelegate.lvnHostAndPort)/auth/user/magic_link?token=\(token!)")
        
        Task {
            //await session.reconnect(url: authURL, httpMethod: "POST", httpBody: httpBody)
            await session.reconnect(url: authURL, httpMethod: "GET")
        }
        
        return true
    }
}

#endif
