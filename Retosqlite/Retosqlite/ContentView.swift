// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CompanyViewModel()
    @State private var showingAddCompany = false
    @State private var companyToDelete: Company? = nil
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Barra de búsqueda
                SearchBar(text: $viewModel.searchText)
                
                // Filtro de clasificación
                ClassificationPicker(selection: $viewModel.selectedClassification)
                
                // Lista de empresas
                List {
                    ForEach(viewModel.filteredCompanies) { company in
                        CompanyRow(company: company)
                            .swipeActions {
                                Button(role: .destructive) {
                                    companyToDelete = company
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .navigationTitle("Directorio de Empresas")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCompany = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCompany) {
                CompanyFormView(mode: .add, viewModel: viewModel)
            }
            .alert("¿Eliminar empresa?", isPresented: $showingDeleteAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Eliminar", role: .destructive) {
                    if let company = companyToDelete {
                        viewModel.deleteCompany(company)
                    }
                }
            } message: {
                if let company = companyToDelete {
                    Text("¿Está seguro que desea eliminar \(company.name)?")
                }
            }
        }
    }
}

