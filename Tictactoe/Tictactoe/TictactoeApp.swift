import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Inicia el monitoreo de red
        NetworkMonitor.shared.startMonitoring()
        
        // Verifica la configuración de Firebase
        print("Configuración de Firebase:")
        if let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            print("- GoogleService-Info.plist encontrado")
            if let dict = NSDictionary(contentsOfFile: filePath) {
                print("- Proyecto ID: \(dict["PROJECT_ID"] ?? "No encontrado")")
                print("- API Key: \(String(describing: dict["API_KEY"]).prefix(5))...")
            }
        }
        
        FirebaseApp.configure()
        return true
    }
}

@main
struct TictactoeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
