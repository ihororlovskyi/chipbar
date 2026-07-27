import XCTest
@testable import sysbar

final class SnapshotTests: XCTestCase {
  func test_zeroSnapshotHasAllZeroValues() {
    let s = Snapshot.zero
    XCTAssertEqual(s.cpu, 0.0)
    XCTAssertEqual(s.gpu, 0.0)
    XCTAssertEqual(s.ram, 0.0)
  }

  func test_snapshotClampsValuesToZeroOneRange() {
    let s = Snapshot(cpu: -0.1, gpu: 1.5, ram: 0.5)
    XCTAssertEqual(s.cpu, 0.0)
    XCTAssertEqual(s.gpu, 1.0)
    XCTAssertEqual(s.ram, 0.5)
  }
}
