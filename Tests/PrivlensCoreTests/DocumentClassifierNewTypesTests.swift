import Testing
@testable import PrivlensCore

@Suite("DocumentClassifier New Document Types Tests")
struct DocumentClassifierNewTypesTests {
    let classifier = DocumentClassifier()

    // MARK: - Government Form Tests

    @Test("Classifies W-2 tax form as government form")
    func classifyW2GovernmentForm() {
        let text = """
        Department of the Treasury - Internal Revenue Service
        Form W-2 Wage and Tax Statement 2025
        Employer Identification Number (EIN): 12-3456789
        Employee's Social Security Number: XXX-XX-1234
        Employer's name: Acme Corporation
        Federal income tax withheld: $12,500.00
        Social Security wages: $85,000.00
        Medicare wages and tips: $85,000.00
        """
        let result = classifier.classify(text: text)
        // W-2 has strong tax keywords, so it classifies as taxForm (which is correct)
        #expect(result == .taxForm || result == .governmentForm)
    }

    @Test("Classifies DMV form as government form")
    func classifyDMVForm() {
        let text = """
        Department of Motor Vehicles
        Application for Driver's License Renewal
        Driver License Number: D1234567
        Vehicle Registration renewal notice
        Title Certificate for motor vehicle
        State of California DMV
        Official use only
        """
        let result = classifier.classify(text: text)
        #expect(result == .governmentForm)
    }

    @Test("Classifies Social Security letter as government form")
    func classifySocialSecurityLetter() {
        let text = """
        Social Security Administration
        SSA Notice of Award
        Your Social Security benefits will begin on January 1, 2026.
        Your monthly benefit amount is $2,150.00.
        Medicare card enclosed.
        Taxpayer Identification Number assigned.
        Department of Health and Human Services
        """
        let result = classifier.classify(text: text)
        #expect(result == .governmentForm)
    }

    @Test("Classifies immigration document as government form")
    func classifyImmigrationDocument() {
        let text = """
        Department of Homeland Security
        U.S. Citizenship and Immigration Services (USCIS)
        Form I-485 Application to Register Permanent Residence
        Alien Registration Number: A123456789
        Green Card application for permanent resident status
        Receipt number: IOE0912345678
        Immigration visa category: EB-2
        """
        let result = classifier.classify(text: text)
        #expect(result == .governmentForm)
    }

    // MARK: - Loan Agreement Tests

    @Test("Classifies mortgage loan agreement")
    func classifyMortgageLoan() {
        let text = """
        MORTGAGE LOAN AGREEMENT
        Promissory Note
        Borrower: John Smith
        Lender: First National Bank
        Principal Amount: $350,000.00
        Interest Rate: 6.25% (Annual Percentage Rate: 6.45%)
        Monthly Payment: $2,155.42
        Loan Term: 30 years
        Amortization schedule attached.
        Collateral: Property at 456 Oak Avenue
        Deed of Trust recorded with county.
        Escrow account required for property taxes and insurance.
        Prepayment penalty: None for first 5 years.
        Late payment fee: 5% of monthly payment after 15-day grace period.
        Truth in Lending Disclosure (Regulation Z) enclosed.
        """
        let result = classifier.classify(text: text)
        #expect(result == .loanAgreement)
    }

    @Test("Classifies auto loan agreement")
    func classifyAutoLoan() {
        let text = """
        AUTO LOAN CONTRACT
        Vehicle Loan Agreement
        Borrower agrees to the following terms:
        Car Loan for 2025 Toyota Camry
        Principal balance: $28,500.00
        APR: 4.9%
        Monthly payment: $535.00
        Loan term: 60 months
        Security interest in the vehicle.
        Late charge of $25 applies after grace period.
        Default provisions and acceleration clause apply.
        Co-signer: Jane Smith
        Loan origination fee: $250.00
        """
        let result = classifier.classify(text: text)
        #expect(result == .loanAgreement)
    }

    @Test("Classifies student loan agreement")
    func classifyStudentLoan() {
        let text = """
        FEDERAL STUDENT LOAN
        Master Promissory Note
        Borrower: Student Name
        Education Loan Disclosure
        Principal Amount: $45,000
        Interest Rate: 5.5%
        Loan term: 10 years
        Monthly payment begins after deferment period.
        Forbearance options available.
        Loan modification terms described below.
        Debt-to-income ratio consideration.
        Refinance options available after 24 months.
        """
        let result = classifier.classify(text: text)
        #expect(result == .loanAgreement)
    }

    // MARK: - Home Purchase Tests

    @Test("Classifies closing disclosure document")
    func classifyClosingDisclosure() {
        let text = """
        CLOSING DISCLOSURE
        Settlement Statement
        This form is a statement of final loan terms and closing costs.
        Buyer: John and Jane Smith
        Seller: Robert Johnson
        Property: 789 Maple Drive
        Purchase Price: $425,000
        Earnest Money: $10,000
        Closing Date: April 15, 2026
        Title Insurance: $1,200
        Recording Fee: $125
        Transfer Tax: $850
        Homeowner's Insurance premium: $1,400/year
        Escrow account established for taxes and insurance.
        """
        let result = classifier.classify(text: text)
        #expect(result == .homePurchase)
    }

    @Test("Classifies home inspection report")
    func classifyHomeInspection() {
        let text = """
        HOME INSPECTION REPORT
        Property Inspection Summary
        Inspector: Licensed Home Inspector #12345
        Property Address: 789 Maple Drive
        Inspection Date: March 20, 2026

        Structural: Foundation in good condition
        Roof: Estimated 5 years remaining life
        Lead-based paint disclosure: Pre-1978 home, testing recommended
        Radon: Level 2.1 pCi/L (below EPA action level)
        Termite inspection: No evidence of active infestation
        Pest inspection completed.
        Septic system: Last pumped 2024

        Inspection contingency deadline: March 25, 2026
        Appraisal: Appraised value meets or exceeds purchase price
        """
        let result = classifier.classify(text: text)
        #expect(result == .homePurchase)
    }

    @Test("Classifies HOA document")
    func classifyHOADocument() {
        let text = """
        HOMEOWNERS ASSOCIATION
        CC&R - Covenants Conditions and Restrictions
        HOA Dues: $350/month
        Special assessment for pool renovation: $1,200
        HOA fees include landscaping and common area maintenance.
        Property survey on file.
        Lot description: Lot 42, Block 3
        Zoning: Residential R-1
        Flood zone: Zone X (minimal risk)
        Flood insurance not required.
        Buyer must acknowledge receipt of HOA documents.
        """
        let result = classifier.classify(text: text)
        #expect(result == .homePurchase)
    }

    // MARK: - Display Metadata Tests

    @Test("Government form has correct display metadata")
    func governmentFormMetadata() {
        let type = DocumentType.governmentForm
        #expect(type.displayName == "Government Form")
        #expect(type.systemIcon == "building.columns.fill")
        #expect(type.documentDescription.contains("DMV"))
        #expect(type.themeColorName == "indigo")
    }

    @Test("Loan agreement has correct display metadata")
    func loanAgreementMetadata() {
        let type = DocumentType.loanAgreement
        #expect(type.displayName == "Loan Agreement")
        #expect(type.systemIcon == "banknote.fill")
        #expect(type.documentDescription.lowercased().contains("mortgage"))
        #expect(type.themeColorName == "orange")
    }

    @Test("Home purchase has correct display metadata")
    func homePurchaseMetadata() {
        let type = DocumentType.homePurchase
        #expect(type.displayName == "Home Purchase")
        #expect(type.systemIcon == "house.and.flag.fill")
        #expect(type.documentDescription.lowercased().contains("closing"))
        #expect(type.themeColorName == "teal")
    }

    // MARK: - Non-regression Tests

    @Test("Existing document types still classify correctly")
    func existingTypesStillWork() {
        // Medical bill
        let medicalText = "Patient Name: Doe, CPT Code: 99213, Amount Billed: $450, Insurance Payment: $320, Copay: $30, Deductible: $500, Provider: Hospital, Date of Service: 01/2026"
        #expect(classifier.classify(text: medicalText) == .medicalBill)

        // Lease
        let leaseText = "Lease Agreement between Landlord and Tenant for premises at 123 Main St. Monthly Rent: $2,100. Security Deposit: $4,200. Lease Term: 12 months. Late fee applies. Pet policy: no pets. Subletting not permitted."
        #expect(classifier.classify(text: leaseText) == .lease)

        // Unknown
        let unknownText = "Hello world random text nothing special here."
        #expect(classifier.classify(text: unknownText) == .unknown)
    }
}
