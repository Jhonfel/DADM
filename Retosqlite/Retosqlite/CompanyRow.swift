// CompanyRow.swift
import SwiftUI

struct CompanyRow: View {
    let company: Company
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(company.name)
                .font(.headline)
            
            HStack {
                Image(systemName: "globe")
                Text(company.websiteURL)
                    .font(.subheadline)
            }
            
            HStack {
                Image(systemName: "phone")
                Text(company.phone)
                    .font(.subheadline)
            }
            
            HStack {
                Image(systemName: "envelope")
                Text(company.email)
                    .font(.subheadline)
            }
            
            Text(company.classification.rawValue)
                .font(.caption)
                .padding(4)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.vertical, 8)
    }
}
