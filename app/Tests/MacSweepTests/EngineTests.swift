import XCTest
@testable import MacSweep

final class EngineTests: XCTestCase {
    private func dump(_ fields: [String]) -> Data { Data((fields.joined(separator: "\0") + "\0").utf8) }

    func testParsesScanFile() throws {
        let data = dump([
            "macsweep-ui-1", "1.1.0", "pt", "1000000", "250000", "/Users/me/Projects", "1", "50", "/Users/me/Library/Logs/macsweep.log", "3",
            "SAFE", "npm cache", "", "", "rm", "81920", "/Users/me/.npm/_cacache\n",
            "SAFE", "Xcode DerivedData", "intermediate builds", "Xcode", "rm", "2048", "/a\n/b c\n",
            "REVIEW", "Docker VM", "inside this file", "!Docker Desktop is not running", "none", "9000", "",
        ])
        let r = try ScanResult.parse(data)
        XCTAssertEqual(r.lang, "pt")
        XCTAssertEqual(r.freeK, 250_000)
        XCTAssertTrue(r.dryRun)
        XCTAssertEqual(r.items.count, 3)
        XCTAssertFalse(r.items[0].blocked)
        XCTAssertEqual(r.items[0].paths, ["/Users/me/.npm/_cacache"])
        XCTAssertTrue(r.items[1].blocked)
        XCTAssertEqual(r.items[1].block, "Xcode")
        XCTAssertEqual(r.items[1].paths, ["/a", "/b c"])
        XCTAssertTrue(r.items[2].blocked)
        XCTAssertTrue(r.items[2].blockIsMessage)
        XCTAssertEqual(r.items[2].block, "Docker Desktop is not running")
        XCTAssertEqual(r.items[2].tier, .review)
    }

    func testRejectsForeignFile() {
        XCTAssertThrowsError(try ScanResult.parse(Data("hello".utf8)))
        XCTAssertThrowsError(try ScanResult.parse(dump(["macsweep-ui-1", "1", "en", "1", "1", "", "0", "50", "", "2"])))
    }

    func testParsesExecEvents() {
        XCTAssertEqual(ExecEvent.parse("S\t3"), .started(3))
        XCTAssertEqual(ExecEvent.parse("D\t3"), .finished(3))
        XCTAssertEqual(ExecEvent.parse("F\t1024\t2048"), .done(freedK: 1024, freeK: 2048))
        XCTAssertNil(ExecEvent.parse("garbage"))
    }

    func testOptionsArguments() {
        let o = ScanOptions(projects: "/p q", days: 10, minMB: 0, fast: true, dryRun: true, lang: "pt")
        XCTAssertEqual(o.arguments, ["--days", "10", "--min-mb", "0", "--lang", "pt", "--projects", "/p q", "--fast", "--dry-run"])
    }

    func testHumanSize() {
        XCTAssertEqual(humanSize(512), "512 KB")
        XCTAssertEqual(humanSize(81920), "80 MB")
        XCTAssertEqual(humanSize(23_173_529), "22.1 GB")
    }
}
