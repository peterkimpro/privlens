import Testing
import Foundation
@testable import PrivlensCore

@Suite("SmartClassifier Tests")
struct SmartClassifierTests {

    let classifier = SmartClassifier()

    @Test("Falls back to keyword classifier for medical bill text")
    func classifyMedicalBill() async {
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
        let result = await classifier.classify(text: text)
        #expect(result == .medicalBill)
    }

    @Test("Falls back to keyword classifier for lease text")
    func classifyLease() async {
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
        let result = await classifier.classify(text: text)
        #expect(result == .lease)
    }

    @Test("Falls back to keyword classifier for NDA text")
    func classifyNDA() async {
        let text = """
        NON-DISCLOSURE AGREEMENT
        This Confidentiality Agreement is entered into between the Disclosing Party
        and the Receiving Party.
        Confidential Information includes all trade secrets, proprietary information,
        business plans, and technical data.
        The receiving party agrees to maintain strict confidentiality.
        Permitted disclosure only to employees with need-to-know.
        Term and termination: This NDA shall remain in effect for 3 years.
        Return of materials upon termination.
        Injunctive relief available for breach.
        Governing law: State of California.
        """
        let result = await classifier.classify(text: text)
        #expect(result == .nda)
    }

    @Test("Returns unknown for empty text")
    func classifyEmpty() async {
        let result = await classifier.classify(text: "")
        #expect(result == .unknown)
    }

    @Test("Returns unknown for short unrecognized text")
    func classifyShortUnrecognized() async {
        let result = await classifier.classify(text: "Hello world.")
        #expect(result == .unknown)
    }

    @Test("Classifies government form text")
    func classifyGovernmentForm() async {
        let text = """
        Department of Motor Vehicles
        Vehicle Registration Renewal
        Driver's License Number: D1234567
        Vehicle Registration expires on 06/30/2026.
        Please visit your local DMV office or renew online.
        State of California
        Official use only.
        Taxpayer Identification Number required.
        """
        let result = await classifier.classify(text: text)
        #expect(result == .governmentForm)
    }

    @Test("Classifies loan agreement text")
    func classifyLoanAgreement() async {
        let text = """
        LOAN AGREEMENT
        Borrower: Jane Smith
        Lender: First National Bank
        Principal Amount: $250,000.00
        Interest Rate: 6.5% Annual Percentage Rate (APR)
        Monthly Payment: $1,580.17
        Loan Term: 30 years, Maturity Date: March 2056
        Collateral: Property at 456 Oak Drive
        Late payment fee of $75 after 15-day grace period.
        Prepayment penalty: None.
        Truth in Lending disclosure attached.
        Escrow account for property taxes and insurance.
        """
        let result = await classifier.classify(text: text)
        #expect(result == .loanAgreement)
    }

    @Test("Classifies home purchase text")
    func classifyHomePurchase() async {
        let text = """
        CLOSING DISCLOSURE
        Settlement Statement for property at 789 Elm Street
        Buyer: John Doe
        Seller: Acme Realty LLC
        Purchase Price: $450,000
        Earnest Money: $10,000
        Title Insurance: $1,200
        Property Tax proration: $3,400
        Homeowners Association (HOA) dues: $250/month
        Home Inspection completed March 15, 2026
        Appraised Value: $455,000
        Closing Date: April 1, 2026
        Recording Fee: $125
        Transfer Tax: $2,250
        """
        let result = await classifier.classify(text: text)
        #expect(result == .homePurchase)
    }

    @Test("Very short text falls back to keyword classifier")
    func shortTextFallback() async {
        // Text shorter than 20 chars goes directly to keyword classifier
        let result = await classifier.classify(text: "short text")
        #expect(result == .unknown)
    }
}

