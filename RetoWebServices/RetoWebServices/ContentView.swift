import SwiftUI
import Charts

struct ExchangeRate: Codable, Identifiable {
    var id: UUID {
        return UUID()
    }
    let valor: String
    let unidad: String
    let vigenciadesde: String
    let vigenciahasta: String
    
    private enum CodingKeys: String, CodingKey {
        case valor, unidad, vigenciadesde, vigenciahasta
    }
}

struct ContentView: View {
    @State private var exchangeRates: [ExchangeRate] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingGraph = false
    @State private var selectedElement: ChartData?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    Picker("Vista", selection: $showingGraph) {
                        Text("Lista").tag(false)
                        Text("Gráfico").tag(true)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    if showingGraph {
                        VStack(spacing: 0) {
                            // Tooltip fijo arriba
                            if let selected = selectedElement {
                                VStack(alignment: .leading) {
                                    Text("Fecha: \(formatDateForDisplay(selected.date))")
                                        .font(.subheadline)
                                    Text("Valor: \(String(format: "%.2f", selected.value)) COP/USD")
                                        .font(.subheadline)
                                        .bold()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondary.opacity(0.1)))
                                .padding(.horizontal)
                            } else {
                                Text("Desliza sobre la gráfica para ver detalles")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                            
                            // Gráfica en un ScrollView para asegurar espacio suficiente
                            ScrollView(.vertical, showsIndicators: false) {
                                chartView
                                    .frame(minHeight: 400) // Aseguramos altura mínima
                            }
                        }
                    } else {
                        listView
                    }
                }
            }
            .navigationTitle("TRM Colombia")
            .onAppear {
                fetchExchangeRates()
            }
        }
    }
    
    var chartView: some View {
        let chartData = prepareChartData()
        return Chart(chartData) { dataPoint in
            LineMark(
                x: .value("Fecha", dataPoint.date),
                y: .value("Valor", dataPoint.value)
            )
            .interpolationMethod(.catmullRom)
            
            if let selected = selectedElement,
               selected.id == dataPoint.id {
                RuleMark(
                    x: .value("Fecha", selected.date)
                )
                .foregroundStyle(.gray.opacity(0.3))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month, count: 3)) { value in
                AxisGridLine()
                AxisValueLabel {
                    Text(formatAxisDate(value.as(Date.self) ?? Date()))
                        .rotationEffect(.degrees(-60))
                        .offset(x: -10, y: 0)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let currentX = value.location.x
                            guard currentX >= 0,
                                  currentX <= geometry.size.width,
                                  let date = proxy.value(atX: currentX, as: Date.self) else {
                                return
                            }
                            
                            if let closest = chartData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
                                selectedElement = closest
                            }
                        })
            }
        }
        .frame(height: 400)  // Aumentamos la altura de 300 a 350
        .padding()
        .padding(.bottom, 40) // Agregamos padding adicional abajo
    }
    
    var listView: some View {
        List(exchangeRates) { rate in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Valor:")
                        .fontWeight(.bold)
                    Text("\(rate.valor) \(rate.unidad)")
                }
                
                HStack {
                    Text("Vigencia:")
                        .fontWeight(.bold)
                    VStack(alignment: .leading) {
                        Text("Desde: \(formatDate(rate.vigenciadesde))")
                        Text("Hasta: \(formatDate(rate.vigenciahasta))")
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    struct ChartData: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }
    
    func prepareChartData() -> [ChartData] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        
        return exchangeRates.compactMap { rate in
            guard let date = dateFormatter.date(from: rate.vigenciadesde),
                  let value = Double(rate.valor.replacingOccurrences(of: ",", with: ".")) else {
                return nil
            }
            return ChartData(date: date, value: value)
        }
        .sorted { $0.date < $1.date }
    }
    
    func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        
        if let date = inputFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "dd/MM/yyyy"
            return outputFormatter.string(from: date)
        }
        return dateString
    }
    
    func formatDateForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
    
    func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "es_CO")
        return formatter.string(from: date).capitalized
    }
    
    func fetchExchangeRates() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "https://www.datos.gov.co/resource/mcec-87by.json") else {
            errorMessage = "URL inválida"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Error de conexión: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No se recibieron datos"
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let rates = try decoder.decode([ExchangeRate].self, from: data)
                    exchangeRates = rates.sorted { $0.vigenciadesde > $1.vigenciahasta }
                } catch {
                    errorMessage = "Error al procesar datos: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

#Preview {
    ContentView()
}
