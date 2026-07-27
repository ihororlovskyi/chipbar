import XCTest
@testable import sysbar

final class RAMReaderTests: XCTestCase {
  func test_usedRatioFormula() {
    // 100 internal + 200 wired + 50 compressed = 350 used. Total pages = 1000.
    let snap = VMSample(
      pageSize: 16_384,
      totalPages: 1_000,
      internalPages: 100,
      wiredPages: 200,
      compressedPages: 50
    )
    let reader = RAMReader(provider: { snap })
    XCTAssertEqual(reader.sample(), 0.35, accuracy: 0.0001)
  }

  func test_zeroTotalReturnsZero() {
    let snap = VMSample(
      pageSize: 16_384, totalPages: 0,
      internalPages: 0, wiredPages: 0, compressedPages: 0
    )
    XCTAssertEqual(RAMReader(provider: { snap }).sample(), 0.0)
  }

  func test_fullyUsedReturnsOne() {
    let snap = VMSample(
      pageSize: 16_384, totalPages: 100,
      internalPages: 60, wiredPages: 30, compressedPages: 10
    )
    XCTAssertEqual(RAMReader(provider: { snap }).sample(), 1.0, accuracy: 0.0001)
  }
}
