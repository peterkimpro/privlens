import Foundation
import Testing
@testable import PrivlensCore

@Suite("PaywallService Tests")
struct PaywallServiceTests {

    /// Returns a unique temp file path for test isolation.
    private static func tempUsagePath() -> String {
        let dir = NSTemporaryDirectory()
        return dir + "PrivlensTest/\(UUID().uuidString)/usage.json"
    }

    /// Helper: writes a UsageRecord directly to the given file path.
    private static func writeUsageRecord(analysisCount: Int, monthYear: String, to path: String) {
        let record = UsageRecord(analysisCount: analysisCount, monthYear: monthYear)
        let url = URL(fileURLWithPath: path)
        let directory = url.deletingLastPathComponent().path
        if !FileManager.default.fileExists(atPath: directory) {
            try? FileManager.default.createDirectory(
                atPath: directory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        let data = try! JSONEncoder().encode(record)
        try! data.write(to: url, options: .atomic)
    }

    /// Returns the current month-year string matching PaywallService's internal format.
    private static func currentMonthYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }

    // MARK: - Free Tier Limits

    @Test("Free user can analyze when under limit")
    func freeUserCanAnalyzeUnderLimit() async {
        let path = Self.tempUsagePath()
        let service = PaywallService(tier: .free, usageFilePath: path)

        let canAnalyze = await service.canPerformAnalysis()
        #expect(canAnalyze == true)
    }

    @Test("Free user cannot analyze when at limit")
    func freeUserCannotAnalyzeAtLimit() async {
        let path = Self.tempUsagePath()
        Self.writeUsageRecord(
            analysisCount: PaywallService.freeMonthlyLimit,
            monthYear: Self.currentMonthYear(),
            to: path
        )
        let service = PaywallService(tier: .free, usageFilePath: path)

        let canAnalyze = await service.canPerformAnalysis()
        #expect(canAnalyze == false)
    }

    @Test("Recording analysis increments the counter")
    func recordAnalysisIncrements() async {
        let path = Self.tempUsagePath()
        let service = PaywallService(tier: .free, usageFilePath: path)

        let before = await service.remainingFreeAnalyses()
        #expect(before == PaywallService.freeMonthlyLimit)

        await service.recordAnalysis()

        let after = await service.remainingFreeAnalyses()
        #expect(after == PaywallService.freeMonthlyLimit - 1)
    }

    @Test("Remaining analyses decreases correctly with each recording")
    func remainingAnalysesDecreasesCorrectly() async {
        let path = Self.tempUsagePath()
        let service = PaywallService(tier: .free, usageFilePath: path)

        for i in 0..<PaywallService.freeMonthlyLimit {
            let remaining = await service.remainingFreeAnalyses()
            #expect(remaining == PaywallService.freeMonthlyLimit - i)
            await service.recordAnalysis()
        }

        let remaining = await service.remainingFreeAnalyses()
        #expect(remaining == 0)
    }

    // MARK: - Pro Tier Bypass

    @Test("Pro user can always analyze")
    func proUserCanAlwaysAnalyze() async {
        let path = Self.tempUsagePath()
        let service = PaywallService(tier: .pro, usageFilePath: path)

        let canAnalyze = await service.canPerformAnalysis()
        #expect(canAnalyze == true)
    }

    @Test("Pro user has Int.max remaining analyses")
    func proUserHasMaxRemaining() async {
        let path = Self.tempUsagePath()
        let service = PaywallService(tier: .pro, usageFilePath: path)

        let remaining = await service.remainingFreeAnalyses()
        #expect(remaining == Int.max)
    }

    @Test("Recording analysis as pro is a no-op")
    func proRecordAnalysisIsNoOp() async {
        let path = Self.tempUsagePath()
        let service = PaywallService(tier: .pro, usageFilePath: path)

        await service.recordAnalysis()

        // File should not have been created since pro skips recording.
        let fileExists = FileManager.default.fileExists(atPath: path)
        #expect(fileExists == false)

        // Remaining should still be Int.max.
        let remaining = await service.remainingFreeAnalyses()
        #expect(remaining == Int.max)
    }

    // MARK: - Monthly Reset

    @Test("Usage resets in a new month")
    func usageResetsInNewMonth() async {
        let path = Self.tempUsagePath()

        // Pre-populate with old month data at the limit.
        Self.writeUsageRecord(
            analysisCount: PaywallService.freeMonthlyLimit,
            monthYear: "2020-01",
            to: path
        )

        let service = PaywallService(tier: .free, usageFilePath: path)

        // Old month data should be ignored, so full limit is available.
        let remaining = await service.remainingFreeAnalyses()
        #expect(remaining == PaywallService.freeMonthlyLimit)

        let canAnalyze = await service.canPerformAnalysis()
        #expect(canAnalyze == true)
    }

    // MARK: - Usage Persistence

    @Test("Usage survives service recreation")
    func usagePersistsAcrossRecreation() async {
        let path = Self.tempUsagePath()

        // First service instance records two analyses.
        let service1 = PaywallService(tier: .free, usageFilePath: path)
        await service1.recordAnalysis()
        await service1.recordAnalysis()

        // Second service instance at the same path should see the usage.
        let service2 = PaywallService(tier: .free, usageFilePath: path)
        let remaining = await service2.remainingFreeAnalyses()
        #expect(remaining == PaywallService.freeMonthlyLimit - 2)
    }

    // MARK: - Protocol Conformance

    @Test("PaywallService conforms to PaywallServiceProtocol")
    func protocolConformance() {
        let path = Self.tempUsagePath()
        let service = PaywallService(tier: .free, usageFilePath: path)
        let _: any PaywallServiceProtocol = service
    }

    // MARK: - Tier Property

    @Test("currentTier reflects initialization value")
    func currentTierReflectsInit() {
        let freePath = Self.tempUsagePath()
        let freeService = PaywallService(tier: .free, usageFilePath: freePath)
        #expect(freeService.currentTier == .free)

        let proPath = Self.tempUsagePath()
        let proService = PaywallService(tier: .pro, usageFilePath: proPath)
        #expect(proService.currentTier == .pro)
    }
}
