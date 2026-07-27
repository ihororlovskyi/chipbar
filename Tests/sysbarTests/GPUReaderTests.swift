import XCTest
@testable import sysbar

final class GPUReaderTests: XCTestCase {
  func test_mockReturnsScriptedValues() {
    var queue: [Double] = [0.0, 0.25, 0.75]
    let mock = MockGPUReader(samples: { queue.removeFirst() })
    XCTAssertEqual(mock.sample(), 0.0)
    XCTAssertEqual(mock.sample(), 0.25)
    XCTAssertEqual(mock.sample(), 0.75)
  }
}
