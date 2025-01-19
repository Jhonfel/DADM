// Company.swift
struct Company: Identifiable {
    var id: Int?  
    var name: String
    var websiteURL: String
    var phone: String
    var email: String
    var productsAndServices: String
    var classification: CompanyClassification
}

enum CompanyClassification: String, CaseIterable {
    case consulting = "Consultoría"
    case customDevelopment = "Desarrollo a la medida"
    case softwareFactory = "Fábrica de software"
}
