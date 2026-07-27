import Foundation

actor MetricsSampler {
  static let minimumIntervalSeconds: Double = 0.5

  private let cpu: any CPUReading
  private let gpu: any GPUReading
  private let ram: any RAMReading
  private var intervalSeconds: Double
  private let continuation: AsyncStream<Snapshot>.Continuation
  private var sleepTask: Task<Void, Never>?
  private var running = false

  /// Stream of snapshots. Single-subscriber.
  nonisolated let snapshots: AsyncStream<Snapshot>

  init(cpu: any CPUReading, gpu: any GPUReading, ram: any RAMReading, initialInterval: Double) {
    self.cpu = cpu
    self.gpu = gpu
    self.ram = ram
    self.intervalSeconds = max(Self.minimumIntervalSeconds, initialInterval)
    let (stream, cont) = AsyncStream<Snapshot>.makeStream(bufferingPolicy: .bufferingNewest(1))
    self.snapshots = stream
    self.continuation = cont
  }

  func start() async throws {
    running = true
    while running {
      let snap = Snapshot(cpu: cpu.sample(), gpu: gpu.sample(), ram: ram.sample())
      continuation.yield(snap)
      await sleepWithCancellation(seconds: intervalSeconds)
    }
  }

  func setInterval(_ seconds: Double) {
    intervalSeconds = max(Self.minimumIntervalSeconds, seconds)
    sleepTask?.cancel()
  }

  func stop() {
    running = false
    sleepTask?.cancel()
    continuation.finish()
  }

  private func sleepWithCancellation(seconds: Double) async {
    let nanos = UInt64(max(Self.minimumIntervalSeconds, seconds) * 1_000_000_000)
    let t = Task<Void, Never> {
      try? await Task.sleep(nanoseconds: nanos)
    }
    sleepTask = t
    _ = await t.value
    sleepTask = nil
  }
}
