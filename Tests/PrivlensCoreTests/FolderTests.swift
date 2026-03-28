import Foundation
import Testing
@testable import PrivlensCore

@Suite("Folder Model Tests")
struct FolderTests {

    @Test("Folder initializes with correct defaults")
    func folderInitialization() {
        let folder = Folder(name: "Medical")
        #expect(folder.name == "Medical")
        #expect(folder.iconName == "folder.fill")
        #expect(folder.colorHex == "007AFF")
        #expect(folder.sortOrder == 0)
    }

    @Test("Folder initializes with custom values")
    func folderCustomInit() {
        let folder = Folder(name: "Bills", iconName: "creditcard.fill", colorHex: "FF0000", sortOrder: 2)
        #expect(folder.name == "Bills")
        #expect(folder.iconName == "creditcard.fill")
        #expect(folder.colorHex == "FF0000")
        #expect(folder.sortOrder == 2)
    }

    @Test("Folder IDs are unique")
    func folderIdentifiable() {
        let f1 = Folder(name: "A")
        let f2 = Folder(name: "B")
        #expect(f1.id != f2.id)
    }

    @Test("Folder dateCreated is set on init")
    func folderDateCreated() {
        let before = Date()
        let folder = Folder(name: "Test")
        let after = Date()
        #expect(folder.dateCreated >= before)
        #expect(folder.dateCreated <= after)
    }
}

@Suite("Document Store Search Tests")
struct DocumentStoreSearchTests {

    @Test("Full text search matches title")
    func fullTextSearchMatchesTitle() throws {
        let store = try DocumentStore()
        let doc = Document(title: "Medical Bill from Hospital", rawText: "Amount due: $500", documentType: .medicalBill)
        try store.save(doc)
        let results = try store.fullTextSearch(query: "hospital")
        #expect(results.count == 1)
        #expect(results.first?.id == doc.id)
    }

    @Test("Full text search matches raw text")
    func fullTextSearchMatchesRawText() throws {
        let store = try DocumentStore()
        let doc = Document(title: "Some Document", rawText: "Your lease agreement for apartment 5B", documentType: .lease)
        try store.save(doc)
        let results = try store.fullTextSearch(query: "apartment")
        #expect(results.count == 1)
    }

    @Test("Full text search returns empty for no match")
    func fullTextSearchNoMatch() throws {
        let store = try DocumentStore()
        let doc = Document(title: "Insurance Policy", rawText: "Coverage details here", documentType: .insurance)
        try store.save(doc)
        let results = try store.fullTextSearch(query: "mortgage")
        #expect(results.isEmpty)
    }

    @Test("Full text search is case insensitive")
    func fullTextSearchCaseInsensitive() throws {
        let store = try DocumentStore()
        let doc = Document(title: "IMPORTANT LEASE", rawText: "monthly rent", documentType: .lease)
        try store.save(doc)
        let results = try store.fullTextSearch(query: "important")
        #expect(results.count == 1)
    }

    @Test("Full text search returns multiple matches")
    func fullTextSearchMultipleMatches() throws {
        let store = try DocumentStore()
        let doc1 = Document(title: "First Hospital Bill", rawText: "Emergency room visit", documentType: .medicalBill)
        let doc2 = Document(title: "Second Hospital Bill", rawText: "Follow-up appointment", documentType: .medicalBill)
        let doc3 = Document(title: "Lease Agreement", rawText: "Monthly rent due", documentType: .lease)
        try store.save(doc1)
        try store.save(doc2)
        try store.save(doc3)
        let results = try store.fullTextSearch(query: "hospital")
        #expect(results.count == 2)
    }

    @Test("Full text search with empty query returns empty")
    func fullTextSearchEmptyQuery() throws {
        let store = try DocumentStore()
        let doc = Document(title: "A Document", rawText: "Some text", documentType: .unknown)
        try store.save(doc)
        let results = try store.fullTextSearch(query: "")
        #expect(results.isEmpty)
    }
}
