import XCTest
@testable import sysbar

final class MetricsSamplerTests: XCTestCase {
  func test_emitsSnapshotsAtConfiguredInterval() async throws {
    let cpu = ScriptedReader(values: [0.10, 0.20, 0.30])
    let gpu = MockGPUReader(samples: { 0.50 })
    let ram = ScriptedReader(values: [0.60, 0.60, 0.60])
    let sampler = MetricsSampler(cpu: cpu, gpu: gpu, ram: ram, initialInterval: 1)

    let task = Task { try await sampler.start() }

    var received: [Snapshot] = []
    for await snap in sampler.snapshots.prefix(2) {
      received.append(snap)
    }
    task.cancel()

    XCTAssertEqual(received.count, 2)
    XCTAssertEqual(received[0].cpu, 0.10, accuracy: 0.0001)
    XCTAssertEqual(received[0].gpu, 0.50, accuracy: 0.0001)
    XCTAssertEqual(received[0].ram, 0.60, accuracy: 0.0001)
  }

  func test_setIntervalReschedulesQuickly() async throws {
    let cpu = MockReader(value: 0.0)
    let gpu = MockGPUReader(samples: { 0.0 })
    let ram = MockReader(value: 0.0)
    let sampler = MetricsSampler(cpu: cpu, gpu: gpu, ram: ram, initialInterval: 2)
    let task = Task { try await sampler.start() }

    var iter = sampler.snapshots.makeAsyncIterator()
    _ = await iter.next() // first snapshot fires immediately on start; consume it.

    // Sampler is now sleeping for 2 s. Reduce to 1 s; next snapshot must arrive within ~1.5 s.
    let start = Date()
    await sampler.setInterval(1)
    _ = await iter.next()
    let elapsed = Date().timeIntervalSince(start)

    task.cancel()
    XCTAssertLessThan(elapsed, 1.5)
  }
}

// Test doubles.

final class ScriptedReader: CPUReading, RAMReading {
  private var values: [Double]
  init(values: [Double]) { self.values = values }
  func sample() -> Double {
    guard !values.isEmpty else { return 0.0 }
    return values.removeFirst()
  }
}

final class MockReader: CPUReading, RAMReading {
  let value: Double
  init(value: Double) { self.value = value }
  func sample() -> Double { value }
}
