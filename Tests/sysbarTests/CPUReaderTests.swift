import XCTest
@testable import sysbar

final class CPUReaderTests: XCTestCase {
  func test_firstSampleReturnsZero() {
    var ticks: [CPUTicks] = [CPUTicks(user: 100, system: 50, idle: 850, nice: 0)]
    let reader = CPUReader(provider: { ticks.removeFirst() })
    XCTAssertEqual(reader.sample(), 0.0)
  }

  func test_allBusyTicksMeansFullLoad() {
    var queue: [CPUTicks] = [
      CPUTicks(user: 0, system: 0, idle: 0, nice: 0),
      CPUTicks(user: 100, system: 0, idle: 0, nice: 0),
    ]
    let reader = CPUReader(provider: { queue.removeFirst() })
    _ = reader.sample() // primes baseline
    XCTAssertEqual(reader.sample(), 1.0, accuracy: 0.0001)
  }

  func test_allIdleTicksMeansZeroLoad() {
    var queue: [CPUTicks] = [
      CPUTicks(user: 0, system: 0, idle: 0, nice: 0),
      CPUTicks(user: 0, system: 0, idle: 100, nice: 0),
    ]
    let reader = CPUReader(provider: { queue.removeFirst() })
    _ = reader.sample()
    XCTAssertEqual(reader.sample(), 0.0, accuracy: 0.0001)
  }

  func test_mixedTicksProducesExpectedRatio() {
    var queue: [CPUTicks] = [
      CPUTicks(user: 0, system: 0, idle: 0, nice: 0),
      CPUTicks(user: 30, system: 10, idle: 60, nice: 0),
    ]
    let reader = CPUReader(provider: { queue.removeFirst() })
    _ = reader.sample()
    XCTAssertEqual(reader.sample(), 0.40, accuracy: 0.0001)
  }

  func test_zeroDeltaReturnsZero() {
    let same = CPUTicks(user: 5, system: 5, idle: 5, nice: 5)
    var queue = [same, same]
    let reader = CPUReader(provider: { queue.removeFirst() })
    _ = reader.sample()
    XCTAssertEqual(reader.sample(), 0.0)
  }
}
