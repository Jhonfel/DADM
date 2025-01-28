import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @AppStorage("searchRadius") private var searchRadius: Double = 1.0
    @State private var points: [POIItem] = []
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var isSliderDragging = false
    @State private var currentCategory: String? = "hospital"
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 4.6097, longitude: -74.0817),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        NavigationView {
            ZStack {
                if locationManager.authorizationStatus == .authorizedWhenInUse ||
                   locationManager.authorizationStatus == .authorizedAlways {
                    MapView(region: $region, points: points)
                        .edgesIgnoringSafeArea(.all)
                } else {
                    VStack {
                        Text("Se requiere acceso a la ubicación")
                            .font(.headline)
                        Text("Por favor, habilita el acceso a la ubicación en la configuración")
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Abrir Configuración") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Text("Radio: \(searchRadius, specifier: "%.1f") km")
                        Slider(value: $searchRadius, in: 0.1...5.0, step: 0.1)
                            .padding()
                            .onHover { hovering in
                                isSliderDragging = hovering
                            }
                            .onChange(of: searchRadius) { newValue in
                                // Cancelar cualquier búsqueda pendiente
                                searchTask?.cancel()
                                
                                // Crear una nueva tarea de búsqueda con delay
                                searchTask = Task {
                                    try? await Task.sleep(nanoseconds: 500_000_000) // 500ms delay
                                    
                                    // Verificar si la tarea no fue cancelada
                                    if !Task.isCancelled {
                                        await MainActor.run {
                                            if let lastCategory = currentCategory {
                                                searchNearbyPlaces(category: lastCategory)
                                            }
                                        }
                                    }
                                }
                            }
                    }
                    .padding()
                    .background(Material.regular)
                    .cornerRadius(10)
                    .padding()
                }
            }
            .navigationTitle("Puntos de Interés")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Hospitales") {
                            searchNearbyPlaces(category: "hospital")
                        }
                        Button("Lugares turísticos") {
                            searchNearbyPlaces(category: "tourist_attraction")
                        }
                        Button("Restaurantes") {
                            searchNearbyPlaces(category: "restaurant")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            checkLocationAuthorization()
        }
    }
    
    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            if let location = locationManager.location {
                region.center = location.coordinate
                searchNearbyPlaces(category: "hospital")
            }
        case .denied, .restricted:
            errorMessage = "La aplicación necesita acceso a la ubicación para funcionar"
            showingError = true
        @unknown default:
            break
        }
    }
    
    private func searchNearbyPlaces(category: String) {
        currentCategory = category
        guard let location = locationManager.location else {
            errorMessage = "No se pudo obtener la ubicación actual"
            showingError = true
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = category
        
        // Establecemos una región más grande para la búsqueda inicial
        let searchRegion = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 5000, // 5km para asegurar que obtengamos suficientes resultados
            longitudinalMeters: 5000
        )
        request.region = searchRegion
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                errorMessage = "Error al buscar lugares: \(error.localizedDescription)"
                showingError = true
                return
            }
            
            guard let response = response else {
                errorMessage = "No se encontraron resultados"
                showingError = true
                return
            }
            
            // Filtrar los resultados por distancia real
            let filteredPoints = response.mapItems.compactMap { item -> POIItem? in
                let itemLocation = CLLocation(latitude: item.placemark.coordinate.latitude,
                                            longitude: item.placemark.coordinate.longitude)
                
                // Calcular la distancia real en kilómetros
                let distance = location.distance(from: itemLocation) / 1000.0
                
                // Solo incluir puntos dentro del radio especificado
                if distance <= searchRadius {
                    return POIItem(
                        name: item.name ?? "Desconocido",
                        coordinate: item.placemark.coordinate,
                        distance: distance
                    )
                }
                return nil
            }
            
            // Actualizar los puntos en el mapa
            points = filteredPoints
            
            // Si no hay resultados dentro del radio, mostrar mensaje
            if filteredPoints.isEmpty {
                errorMessage = "No se encontraron lugares dentro del radio de \(searchRadius) km"
                showingError = true
            }
        }
    }
}

struct MapView: View {
    @Binding var region: MKCoordinateRegion
    let points: [POIItem]
    
    var body: some View {
        Map(coordinateRegion: $region,
            showsUserLocation: true,
            annotationItems: points) { point in
            MapAnnotation(coordinate: point.coordinate) {
                VStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                        .font(.title)
                    Text(point.name)
                        .font(.caption)
                        .padding(4)
                        .background(Material.regular)
                        .cornerRadius(4)
                }
            }
        }
    }
}

struct POIItem: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let distance: Double // distancia en kilómetros
}

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    
    override init() {
        authorizationStatus = .notDetermined
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdating() {
        locationManager.startUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            startUpdating()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error de ubicación: \(error.localizedDescription)")
    }
}
