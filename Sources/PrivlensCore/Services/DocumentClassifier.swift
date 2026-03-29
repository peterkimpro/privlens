import Foundation

public final class DocumentClassifier: Sendable {

    public init() {}

    /// Classifies a document based on keyword matching against its text content.
    public func classify(text: String) -> DocumentType {
        let lowercased = text.lowercased()

        let scores: [(DocumentType, Int)] = [
            (.medicalBill, scoreMedicalBill(lowercased)),
            (.lease, scoreLease(lowercased)),
            (.insurance, scoreInsurance(lowercased)),
            (.taxForm, scoreTaxForm(lowercased)),
            (.employmentContract, scoreEmploymentContract(lowercased)),
            (.nda, scoreNDA(lowercased)),
        ]

        guard let best = scores.max(by: { $0.1 < $1.1 }), best.1 > 0 else {
            return .unknown
        }

        return best.0
    }

    // MARK: - Scoring Functions

    private func scoreMedicalBill(_ text: String) -> Int {
        let keywords = [
            "eob", "explanation of benefits",
            "patient name", "patient id", "medical record",
            "diagnosis", "diagnosis code", "icd",
            "cpt", "procedure code",
            "amount billed", "amount charged", "total charges",
            "insurance payment", "insurance paid", "plan paid",
            "patient responsibility", "amount you owe", "balance due",
            "copay", "co-pay", "coinsurance",
            "deductible",
            "provider", "physician", "hospital",
            "date of service", "service date",
            "claim number", "claim #",
            "medical", "health plan",
            "emergency room", "laboratory", "radiology",
            "prescription", "pharmacy",
        ]
        return countMatches(in: text, keywords: keywords)
    }

    private func scoreLease(_ text: String) -> Int {
        let keywords = [
            "lease agreement", "rental agreement", "lease contract",
            "landlord", "tenant", "lessee", "lessor",
            "premises", "property address", "unit",
            "monthly rent", "rent amount", "rent due",
            "security deposit", "damage deposit",
            "lease term", "lease period", "commencement date",
            "move-in", "move-out", "vacate",
            "eviction", "notice to quit",
            "maintenance", "repairs",
            "pet policy", "pets allowed", "no pets",
            "subletting", "sublease",
            "utilities", "parking",
            "late fee", "late payment",
            "renewal", "month-to-month",
            "quiet enjoyment", "habitable",
        ]
        return countMatches(in: text, keywords: keywords)
    }

    private func scoreInsurance(_ text: String) -> Int {
        let keywords = [
            "insurance policy", "policy number", "policy #",
            "premium", "monthly premium", "annual premium",
            "deductible", "out-of-pocket",
            "coverage", "covered", "exclusion", "not covered",
            "beneficiary", "insured", "policyholder",
            "claim", "claims process", "file a claim",
            "liability", "comprehensive", "collision",
            "underwriter", "underwriting",
            "effective date", "expiration date",
            "cancellation", "termination",
            "rider", "endorsement", "addendum",
            "indemnity", "indemnification",
            "waiting period", "pre-existing",
            "network", "in-network", "out-of-network",
            "copayment", "coinsurance",
            "maximum benefit", "lifetime maximum",
        ]
        return countMatches(in: text, keywords: keywords)
    }

    private func scoreTaxForm(_ text: String) -> Int {
        let keywords = [
            "w-2", "w2", "wage and tax statement",
            "1099", "1099-misc", "1099-nec", "1099-int", "1099-div",
            "1040", "form 1040",
            "tax return", "tax form",
            "adjusted gross income", "agi",
            "taxable income", "tax liability",
            "federal income tax withheld", "state income tax",
            "social security wages", "medicare wages",
            "employer identification number", "ein",
            "filing status", "standard deduction",
            "tax credit", "earned income",
            "withholding", "estimated tax",
            "irs", "internal revenue service",
            "tax year", "fiscal year",
            "schedule a", "schedule b", "schedule c", "schedule d",
            "dependent", "exemption",
            "refund", "amount owed",
            "quarterly payment", "self-employment tax",
        ]
        return countMatches(in: text, keywords: keywords)
    }

    private func scoreEmploymentContract(_ text: String) -> Int {
        let keywords = [
            "employment agreement", "employment contract",
            "employee", "employer",
            "job title", "position", "role",
            "compensation", "base salary", "annual salary",
            "start date", "commencement",
            "probationary period", "probation",
            "benefits", "health insurance", "retirement",
            "paid time off", "pto", "vacation days",
            "termination", "at-will", "at will",
            "severance", "severance pay",
            "non-compete", "non-solicitation",
            "intellectual property", "work product",
            "confidentiality", "proprietary information",
            "duties and responsibilities",
            "performance review", "performance evaluation",
            "bonus", "stock options", "equity",
            "overtime", "work hours", "working hours",
            "relocation", "remote work",
            "notice period", "resignation",
            "background check", "drug test",
        ]
        return countMatches(in: text, keywords: keywords)
    }

    private func scoreNDA(_ text: String) -> Int {
        let keywords = [
            "non-disclosure agreement", "nda",
            "confidentiality agreement",
            "confidential information", "proprietary information",
            "disclosing party", "receiving party",
            "trade secret", "trade secrets",
            "intellectual property",
            "obligation of confidentiality",
            "permitted disclosure", "authorized disclosure",
            "return of materials", "destruction of materials",
            "term and termination",
            "injunctive relief", "equitable relief",
            "breach", "remedy", "remedies",
            "governing law", "jurisdiction",
            "mutual nda", "unilateral",
            "exclusions from confidential",
            "residual knowledge",
            "non-circumvention",
            "survival", "surviving obligations",
            "indemnification",
        ]
        return countMatches(in: text, keywords: keywords)
    }

    private func countMatches(in text: String, keywords: [String]) -> Int {
        keywords.reduce(0) { count, keyword in
            count + (text.contains(keyword) ? 1 : 0)
        }
    }
}
