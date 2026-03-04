import SwiftUI

@main
struct BoiliTTimerApp: App {
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    notificationManager.requestAuthorization()
                }
        }
    }
}
