import SwiftUI

class CompanyViewModel: ObservableObject {
    @Published var companies: [Company] = []
    @Published var searchText = ""
    @Published var selectedClassification: CompanyClassification?
    
    private let databaseManager = DatabaseManager.shared
    
    init() {
        loadCompanies()
    }
    
    func loadCompanies() {
        companies = databaseManager.getAllCompanies()
    }
    
    func addCompany(_ company: Company) {
        if let id = databaseManager.createCompany(company) {
            var newCompany = company
            newCompany.id = Int(id)
            companies.append(newCompany)
        }
    }
    
    func updateCompany(_ company: Company) {
        if databaseManager.updateCompany(company) {
            if let index = companies.firstIndex(where: { $0.id == company.id }) {
                companies[index] = company
            } 
        }
    }
    
    func deleteCompany(_ company: Company) {
        if let id = company.id, databaseManager.deleteCompany(id) {
            companies.removeAll { $0.id == company.id }
        }
    }
    
    var filteredCompanies: [Company] {
        var filtered = companies
        
        // Filtrar por texto de búsqueda
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Filtrar por clasificación
        if let classification = selectedClassification {
            filtered = filtered.filter { $0.classification == classification }
        }
        
        return filtered
    }
}
