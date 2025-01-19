import Network

class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    
    func startMonitoring() {
        print("Iniciando monitoreo de red...")
        monitor.pathUpdateHandler = { path in
            print("Estado de la conexión:")
            print("- Conectado: \(path.status == .satisfied)")
            print("- Tipo de conexión: \(path.isExpensive ? "Datos móviles" : "WiFi")")
            print("- Interfaces disponibles: \(path.availableInterfaces.map { $0.debugDescription })")
            print("- Soporte IPv6: \(path.supportsIPv6)")
            
            if path.status != .satisfied {
                print("- Razón de fallo: \(path.unsatisfiedReason)")
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
}
