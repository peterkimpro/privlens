import Testing
@testable import PrivlensCore

@Suite("DocumentClassifier Tests")
struct DocumentClassifierTests {
    let classifier = DocumentClassifier()

    @Test("Classifies medical bill text")
    func classifyMedicalBill() {
        let text = """
        Patient Name: John Doe
        Date of Service: 01/15/2026
        Diagnosis Code: ICD-10 R50.9
        CPT Code: 99213
        Amount Billed: $450.00
        Insurance Payment: $320.00
        Patient Responsibility: $130.00
        Copay: $30.00
        Deductible remaining: $1,500
        Provider: Dr. Smith, General Hospital
        """
        let result = classifier.classify(text: text)
        #expect(result == .medicalBill)
    }

    @Test("Classifies lease agreement text")
    func classifyLease() {
        let text = """
        LEASE AGREEMENT
        This lease agreement is entered into between the Landlord
        and Tenant for the premises located at 123 Main Street, Unit 4B.
        Monthly Rent: $2,100 due on the 1st of each month.
        Security Deposit: $4,200
        Lease Term: 12 months, commencement date August 1, 2026.
        Late fee of $50 applies after the 5th of each month.
        Pet policy: No pets allowed without written consent.
        Subletting is not permitted without landlord approval.
        """
        let result = classifier.classify(text: text)
        #expect(result == .lease)
    }

    @Test("Classifies insurance document text")
    func classifyInsurance() {
        let text = """
        INSURANCE POLICY
        Policy Number: HO-2026-44891
        Policyholder: Jane Smith
        Coverage: Comprehensive homeowners insurance
        Annual Premium: $1,800
        Deductible: $2,500
        Liability coverage limit: $300,000
        Effective Date: March 1, 2026
        Expiration Date: March 1, 2027
        Exclusions: Flood damage, earthquake damage not covered.
        Filing a claim: Contact claims department within 30 days.
        Cancellation: 30-day written notice required.
        """
        let result = classifier.classify(text: text)
        #expect(result == .insurance)
    }

    @Test("Returns unknown for unrecognized text")
    func classifyUnknown() {
        let text = "Hello world, this is a random piece of text with no document keywords."
        let result = classifier.classify(text: text)
        #expect(result == .unknown)
    }

    @Test("Returns unknown for empty text")
    func classifyEmpty() {
        let result = classifier.classify(text: "")
        #expect(result == .unknown)
    }
}
