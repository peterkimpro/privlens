import Foundation
import Testing
@testable import PrivlensCore

@Suite("AppReadinessChecker Tests")
struct AppReadinessCheckerTests {

    @Test("Readiness report contains expected checks")
    func reportContainsExpectedChecks() {
        let checker = AppReadinessChecker()
        let report = checker.checkReadiness()

        // Should have at least 5 checks
        #expect(report.checks.count >= 5)

        // Check that named checks exist
        let checkNames = Set(report.checks.map(\.name))
        #expect(checkNames.contains("Platform"))
        #expect(checkNames.contains("AI Engine"))
        #expect(checkNames.contains("Storage Access"))
        #expect(checkNames.contains("Disk Space"))
        #expect(checkNames.contains("Camera"))
    }

    @Test("Storage access check passes on writable systems")
    func storageAccessPasses() {
        let checker = AppReadinessChecker()
        let report = checker.checkReadiness()

        let storageCheck = report.checks.first { $0.name == "Storage Access" }
        #expect(storageCheck != nil)
        // On CI/dev machines, temp directory should be writable
        #expect(storageCheck?.passed == true)
    }

    @Test("Disk space check passes when temp directory is writable")
    func diskSpacePasses() {
        let checker = AppReadinessChecker()
        let report = checker.checkReadiness()

        let diskCheck = report.checks.first { $0.name == "Disk Space" }
        #expect(diskCheck != nil)
        #expect(diskCheck?.passed == true)
    }

    @Test("Report allPassed reflects individual checks")
    func allPassedReflectsChecks() {
        // Create a report manually to test logic
        let checks = [
            ReadinessCheck(name: "A", passed: true, detail: "ok"),
            ReadinessCheck(name: "B", passed: true, detail: "ok"),
        ]
        let report = ReadinessReport(checks: checks)
        #expect(report.allPassed == true)
        #expect(report.passedCount == 2)
        #expect(report.failedCount == 0)
    }

    @Test("Report with failures reflects correctly")
    func reportWithFailures() {
        let checks = [
            ReadinessCheck(name: "A", passed: true, detail: "ok"),
            ReadinessCheck(name: "B", passed: false, detail: "failed"),
        ]
        let report = ReadinessReport(checks: checks)
        #expect(report.allPassed == false)
        #expect(report.passedCount == 1)
        #expect(report.failedCount == 1)
    }

    @Test("ReadinessCheck has unique identifiers")
    func checksHaveUniqueIds() {
        let check1 = ReadinessCheck(name: "A", passed: true, detail: "ok")
        let check2 = ReadinessCheck(name: "B", passed: true, detail: "ok")
        #expect(check1.id != check2.id)
    }
}
