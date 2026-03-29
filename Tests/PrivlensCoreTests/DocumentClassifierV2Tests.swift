import Testing
@testable import PrivlensCore

@Suite("DocumentClassifier v1.1 Tests — New Document Types")
struct DocumentClassifierV2Tests {
    let classifier = DocumentClassifier()

    @Test("Classifies W-2 tax form text")
    func classifyW2TaxForm() {
        let text = """
        Form W-2 Wage and Tax Statement
        Employer Identification Number (EIN): 12-3456789
        Employer Name: Acme Corp
        Employee Social Security Number: XXX-XX-1234
        Wages, tips, other compensation: $85,000.00
        Federal income tax withheld: $14,500.00
        Social Security wages: $85,000.00
        Medicare wages and tips: $85,000.00
        State income tax: $4,250.00
        Tax Year: 2025
        """
        let result = classifier.classify(text: text)
        #expect(result == .taxForm)
    }

    @Test("Classifies 1099 tax form text")
    func classify1099TaxForm() {
        let text = """
        Form 1099-NEC Nonemployee Compensation
        Payer's name: Freelance Co
        Payer's TIN: 98-7654321
        Recipient's TIN: XXX-XX-5678
        Nonemployee compensation: $45,000.00
        Federal income tax withheld: $0.00
        Self-employment tax may apply.
        IRS Internal Revenue Service
        Tax year 2025
        """
        let result = classifier.classify(text: text)
        #expect(result == .taxForm)
    }

    @Test("Classifies employment contract text")
    func classifyEmploymentContract() {
        let text = """
        EMPLOYMENT AGREEMENT
        This Employment Agreement is entered into between the Employer,
        TechCorp Inc., and the Employee, Jane Smith.
        Job Title: Senior Software Engineer
        Base Salary: $150,000 per annum
        Start Date: March 1, 2026
        Probationary Period: 90 days
        Benefits include health insurance, 401k retirement plan, and 20 vacation days.
        Non-compete clause: Employee agrees not to work for competitors
        for 12 months following termination.
        At-will employment. Either party may terminate with 2 weeks notice.
        Stock options: 10,000 shares vesting over 4 years.
        Performance review conducted annually.
        """
        let result = classifier.classify(text: text)
        #expect(result == .employmentContract)
    }

    @Test("Classifies NDA text")
    func classifyNDA() {
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
        Mutual NDA.
        """
        let result = classifier.classify(text: text)
        #expect(result == .nda)
    }

    @Test("NDA keywords do not trigger for general contract")
    func ndaDoesNotTriggerForGeneralContract() {
        let text = """
        This is a general business agreement between two parties
        for the supply of widgets. Payment terms are net 30.
        Delivery within 5 business days. Returns accepted within 14 days.
        """
        let result = classifier.classify(text: text)
        #expect(result != .nda)
    }

    @Test("Tax form does not trigger for medical bill with deductible")
    func taxFormDoesNotTriggerForMedicalBill() {
        let text = """
        Patient Name: John Doe
        Date of Service: 01/15/2026
        Diagnosis Code: ICD-10 R50.9
        Amount Billed: $450.00
        Insurance Payment: $320.00
        Patient Responsibility: $130.00
        Copay: $30.00
        Deductible remaining: $1,500
        Provider: Dr. Smith, General Hospital
        Explanation of Benefits
        """
        let result = classifier.classify(text: text)
        #expect(result == .medicalBill)
    }

    @Test("Employment contract beats NDA when both have confidentiality terms")
    func employmentContractWithConfidentiality() {
        let text = """
        EMPLOYMENT AGREEMENT
        Job title: Product Manager
        Base salary: $120,000 annual compensation
        Employee agrees to maintain confidentiality of proprietary information.
        Non-compete for 6 months after termination.
        Benefits include health insurance and paid time off.
        Probationary period of 90 days.
        At-will employment.
        Start date: January 15, 2026.
        Performance evaluation quarterly.
        Intellectual property belongs to employer.
        """
        let result = classifier.classify(text: text)
        #expect(result == .employmentContract)
    }

    @Test("New document types have correct display names")
    func newTypeDisplayNames() {
        #expect(DocumentType.taxForm.displayName == "Tax Form")
        #expect(DocumentType.employmentContract.displayName == "Employment Contract")
        #expect(DocumentType.nda.displayName == "NDA")
    }

    @Test("New document types have correct system icons")
    func newTypeSystemIcons() {
        #expect(DocumentType.taxForm.systemIcon == "doc.text.fill")
        #expect(DocumentType.employmentContract.systemIcon == "briefcase.fill")
        #expect(DocumentType.nda.systemIcon == "lock.doc.fill")
    }

    @Test("All document types are present in CaseIterable")
    func allTypesInCaseIterable() {
        let allCases = DocumentType.allCases
        #expect(allCases.contains(.taxForm))
        #expect(allCases.contains(.employmentContract))
        #expect(allCases.contains(.nda))
        #expect(allCases.count == 7) // medicalBill, lease, insurance, taxForm, employmentContract, nda, unknown
    }
}
