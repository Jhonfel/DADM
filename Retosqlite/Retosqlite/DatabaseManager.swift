// DatabaseManager.swift
import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    
    private init() {
        createDatabase()
        createTable()
    }
    
    private func createDatabase() {
        let fileURL = try! FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("companies.sqlite")
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("Error opening database")
            return
        }
    }
    
    private func createTable() {
        let createTableQuery = """
            CREATE TABLE IF NOT EXISTS companies (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                website_url TEXT,
                phone TEXT,
                email TEXT,
                products_services TEXT,
                classification TEXT
            );
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Table created successfully")
            }
        }
        sqlite3_finalize(statement)
    }
    

    func createCompany(_ company: Company) -> Int64? {
        let insertQuery = """
            INSERT INTO companies (name, website_url, phone, email, products_services, classification)
            VALUES (?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        var newId: Int64?
        
        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (company.name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (company.websiteURL as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (company.phone as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (company.email as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 5, (company.productsAndServices as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 6, (company.classification.rawValue as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                newId = sqlite3_last_insert_rowid(db)
            }
        }
        sqlite3_finalize(statement)
        return newId
    }

    func getAllCompanies() -> [Company] {
        var companies: [Company] = []
        let queryString = "SELECT * FROM companies;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                let name = String(cString: sqlite3_column_text(statement, 1))
                let websiteURL = String(cString: sqlite3_column_text(statement, 2))
                let phone = String(cString: sqlite3_column_text(statement, 3))
                let email = String(cString: sqlite3_column_text(statement, 4))
                let productsServices = String(cString: sqlite3_column_text(statement, 5))
                let classificationStr = String(cString: sqlite3_column_text(statement, 6))
                
                let classification = CompanyClassification.allCases.first { $0.rawValue == classificationStr } ?? .consulting
                
                let company = Company(
                    id: Int(id),
                    name: name,
                    websiteURL: websiteURL,
                    phone: phone,
                    email: email,
                    productsAndServices: productsServices,
                    classification: classification
                )
                companies.append(company)
            }
        }
        sqlite3_finalize(statement)
        return companies
    }
    

    func updateCompany(_ company: Company) -> Bool {
        let updateQuery = """
            UPDATE companies 
            SET name = ?, website_url = ?, phone = ?, email = ?, products_services = ?, classification = ?
            WHERE id = ?;
        """
        
        var statement: OpaquePointer?
        var success = false
        
        if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (company.name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (company.websiteURL as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (company.phone as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (company.email as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 5, (company.productsAndServices as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 6, (company.classification.rawValue as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(statement, 7, Int64(company.id ?? 0))
            
            success = sqlite3_step(statement) == SQLITE_DONE
        }
        
        sqlite3_finalize(statement)
        return success
    }

    func deleteCompany(_ id: Int) -> Bool {
        let deleteQuery = "DELETE FROM companies WHERE id = ?;"
        var statement: OpaquePointer?
        var success = false
        
        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, Int64(id))
            success = sqlite3_step(statement) == SQLITE_DONE
        }
        
        sqlite3_finalize(statement)
        return success
    }
}
