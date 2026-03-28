import Foundation
import Testing
@testable import PrivlensCore

@Suite("Folder Store Tests")
struct FolderStoreTests {

    @Test("Create and fetch a folder")
    func createAndFetchFolder() throws {
        let store = try DocumentStore()
        let folder = Folder(name: "Medical")
        try store.createFolder(folder)
        let folders = try store.fetchAllFolders()
        #expect(folders.count == 1)
        #expect(folders.first?.name == "Medical")
    }

    @Test("Create multiple folders")
    func createMultipleFolders() throws {
        let store = try DocumentStore()
        let folder1 = Folder(name: "Medical", sortOrder: 0)
        let folder2 = Folder(name: "Bills", sortOrder: 1)
        let folder3 = Folder(name: "Insurance", sortOrder: 2)
        try store.createFolder(folder1)
        try store.createFolder(folder2)
        try store.createFolder(folder3)
        let folders = try store.fetchAllFolders()
        #expect(folders.count == 3)
    }

    @Test("Delete a folder")
    func deleteFolder() throws {
        let store = try DocumentStore()
        let folder = Folder(name: "Temp")
        try store.createFolder(folder)
        try store.deleteFolder(folder)
        let folders = try store.fetchAllFolders()
        #expect(folders.isEmpty)
    }

    @Test("Delete one folder leaves others intact")
    func deleteOneFolderLeavesOthers() throws {
        let store = try DocumentStore()
        let folder1 = Folder(name: "Keep")
        let folder2 = Folder(name: "Remove")
        try store.createFolder(folder1)
        try store.createFolder(folder2)
        try store.deleteFolder(folder2)
        let folders = try store.fetchAllFolders()
        #expect(folders.count == 1)
        #expect(folders.first?.name == "Keep")
    }

    @Test("Fetch unfiled documents returns documents with no folder")
    func fetchUnfiledDocuments() throws {
        let store = try DocumentStore()
        let doc = Document(title: "Unfiled Doc", rawText: "text", documentType: .unknown)
        try store.save(doc)
        let unfiled = try store.fetchUnfiledDocuments()
        #expect(unfiled.count == 1)
        #expect(unfiled.first?.id == doc.id)
    }

    @Test("Fetch unfiled documents excludes filed documents")
    func fetchUnfiledExcludesFiled() throws {
        let store = try DocumentStore()
        let folder = Folder(name: "Medical")
        try store.createFolder(folder)
        let filedDoc = Document(title: "Filed Doc", rawText: "text", documentType: .medicalBill)
        let unfiledDoc = Document(title: "Unfiled Doc", rawText: "text", documentType: .unknown)
        try store.save(filedDoc)
        try store.save(unfiledDoc)
        try store.moveDocument(filedDoc, to: folder)
        let unfiled = try store.fetchUnfiledDocuments()
        #expect(unfiled.count == 1)
        #expect(unfiled.first?.id == unfiledDoc.id)
    }

    @Test("Move document into a folder")
    func moveDocumentIntoFolder() throws {
        let store = try DocumentStore()
        let folder = Folder(name: "Medical")
        try store.createFolder(folder)
        let doc = Document(title: "A Doc", rawText: "text", documentType: .medicalBill)
        try store.save(doc)
        try store.moveDocument(doc, to: folder)
        let docsInFolder = try store.fetchDocuments(in: folder)
        #expect(docsInFolder.count == 1)
        #expect(docsInFolder.first?.id == doc.id)
    }

    @Test("Fetch documents in folder returns only matching documents")
    func fetchDocumentsInFolder() throws {
        let store = try DocumentStore()
        let folder1 = Folder(name: "Medical")
        let folder2 = Folder(name: "Bills")
        try store.createFolder(folder1)
        try store.createFolder(folder2)
        let doc1 = Document(title: "Doc 1", rawText: "text", documentType: .medicalBill)
        let doc2 = Document(title: "Doc 2", rawText: "text", documentType: .lease)
        try store.save(doc1)
        try store.save(doc2)
        try store.moveDocument(doc1, to: folder1)
        try store.moveDocument(doc2, to: folder2)
        let medicalDocs = try store.fetchDocuments(in: folder1)
        #expect(medicalDocs.count == 1)
        #expect(medicalDocs.first?.id == doc1.id)
    }

    @Test("Fetch documents in empty folder returns empty array")
    func fetchDocumentsInEmptyFolder() throws {
        let store = try DocumentStore()
        let folder = Folder(name: "Empty")
        try store.createFolder(folder)
        let docs = try store.fetchDocuments(in: folder)
        #expect(docs.isEmpty)
    }
}
