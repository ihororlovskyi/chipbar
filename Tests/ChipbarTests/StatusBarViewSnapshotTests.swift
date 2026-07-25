import XCTest
@testable import Chipbar

@MainActor
final class StatusBarViewSnapshotTests: XCTestCase {
  func test_cpuOnlyAt50() throws {
    try SnapshotHelpers.assertSnapshot(
      visibility: MetricVisibility(cpu: true, gpu: false, ram: false),
      snapshot: Snapshot(cpu: 0.5, gpu: 0, ram: 0),
      named: "cpu-only-50"
    )
  }

  func test_gpuOnlyAt25() throws {
    try SnapshotHelpers.assertSnapshot(
      visibility: MetricVisibility(cpu: false, gpu: true, ram: false),
      snapshot: Snapshot(cpu: 0, gpu: 0.25, ram: 0),
      named: "gpu-only-25"
    )
  }

  func test_cpuPlusGpu5And25() throws {
    try SnapshotHelpers.assertSnapshot(
      visibility: MetricVisibility(cpu: true, gpu: true, ram: false),
      snapshot: Snapshot(cpu: 0.05, gpu: 0.25, ram: 0),
      named: "cpu-gpu-5-25"
    )
  }

  func test_threeCellsAt50_75_100() throws {
    try SnapshotHelpers.assertSnapshot(
      visibility: .allOn,
      snapshot: Snapshot(cpu: 0.5, gpu: 0.75, ram: 1.0),
      named: "all-50-75-100"
    )
  }

  func test_threeCellsAtZero() throws {
    try SnapshotHelpers.assertSnapshot(
      visibility: .allOn,
      snapshot: Snapshot(cpu: 0, gpu: 0, ram: 0),
      named: "all-zero"
    )
  }
}
