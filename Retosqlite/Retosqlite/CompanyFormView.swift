// CompanyFormView.swift
import SwiftUI

enum FormMode {
    case add
    case edit(Company)
}

struct CompanyFormView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: CompanyViewModel
    
    let mode: FormMode
    
    @State private var name = ""
    @State private var websiteURL = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var productsAndServices = ""
    @State private var classification = CompanyClassification.consulting
    
    private var isEditing: Bool {
        switch mode {
        case .add: return false
        case .edit: return true
        }
    }
    
    init(mode: FormMode, viewModel: CompanyViewModel) {
        self.mode = mode
        self.viewModel = viewModel
        
        // Inicializar los campos si estamos en modo edición
        if case let .edit(company) = mode {
            _name = State(initialValue: company.name)
            _websiteURL = State(initialValue: company.websiteURL)
            _phone = State(initialValue: company.phone)
            _email = State(initialValue: company.email)
            _productsAndServices = State(initialValue: company.productsAndServices)
            _classification = State(initialValue: company.classification)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información básica")) {
                    TextField("Nombre de la empresa", text: $name)
                    TextField("URL del sitio web", text: $websiteURL)
                    TextField("Teléfono", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                }
                
                Section(header: Text("Productos y servicios")) {
                    TextEditor(text: $productsAndServices)
                        .frame(height: 100)
                }
                
                Section(header: Text("Clasificación")) {
                    Picker("Clasificación", selection: $classification) {
                        ForEach(CompanyClassification.allCases, id: \.self) { classification in
                            Text(classification.rawValue).tag(classification)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Editar empresa" : "Nueva empresa")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Guardar" : "Agregar") {
                        let company = Company(
                            id: nil,
                            name: name,
                            websiteURL: websiteURL,
                            phone: phone,
                            email: email,
                            productsAndServices: productsAndServices,
                            classification: classification
                        )
                        
                        if isEditing {
                            viewModel.updateCompany(company)
                        } else {
                            viewModel.addCompany(company)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
