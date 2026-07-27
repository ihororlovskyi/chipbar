import AppKit
import XCTest
@testable import sysbar

final class AboutInfoTests: XCTestCase {
  private let fallback = Date(timeIntervalSince1970: 0)

  func test_parsesValidPlistValue() {
    let date = AboutInfo.releaseDate(plistValue: "2026-07-26", fallback: fallback)
    XCTAssertEqual(AboutInfo.format(date), "26 Jul 26")
  }

  func test_emptyValueFallsBackToProvidedDate() {
    let date = AboutInfo.releaseDate(plistValue: "", fallback: fallback)
    XCTAssertEqual(date, fallback)
  }

  func test_nilValueFallsBackToProvidedDate() {
    let date = AboutInfo.releaseDate(plistValue: nil, fallback: fallback)
    XCTAssertEqual(date, fallback)
  }

  func test_garbageValueFallsBackToProvidedDate() {
    let date = AboutInfo.releaseDate(plistValue: "not-a-date", fallback: fallback)
    XCTAssertEqual(date, fallback)
  }

  func test_impossibleDateIsRejected() {
    let date = AboutInfo.releaseDate(plistValue: "2026-02-30", fallback: fallback)
    XCTAssertEqual(date, fallback, "lenient parsing would silently roll 30 Feb into 2 Mar")
  }

  func test_formatUsesUTCRatherThanLocalTime() {
    // 2026-01-01 23:30 UTC. Rendered in any zone east of UTC+1 — including the
    // developer's own — a local formatter would print "02 Jan 26". Only a
    // UTC-pinned formatter keeps the release date on the day it was stamped.
    let lateInTheUTCDay = Date(timeIntervalSince1970: 1_767_310_200)
    XCTAssertEqual(AboutInfo.format(lateInTheUTCDay), "01 Jan 26")
  }

  func test_creditsContainsClickableRepositoryLink() {
    let url = URL(string: "https://github.com/ihororlovskyi/sysbar")!
    let credits = AboutInfo.credits(dateText: "26 Jul 26", repositoryURL: url)

    XCTAssertTrue(credits.string.contains("26 Jul 26"))
    XCTAssertTrue(credits.string.contains("GitHub"))

    var foundLink: URL?
    credits.enumerateAttribute(.link, in: NSRange(location: 0, length: credits.length)) { value, _, _ in
      if let value = value as? URL { foundLink = value }
    }
    XCTAssertEqual(foundLink, url)
  }
}
