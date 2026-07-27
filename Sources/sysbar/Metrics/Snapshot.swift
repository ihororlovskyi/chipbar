import Foundation

struct Snapshot: Equatable, Sendable {
  let cpu: Double
  let gpu: Double
  let ram: Double

  init(cpu: Double, gpu: Double, ram: Double) {
    self.cpu = Self.clamp(cpu)
    self.gpu = Self.clamp(gpu)
    self.ram = Self.clamp(ram)
  }

  static let zero = Snapshot(cpu: 0, gpu: 0, ram: 0)

  private static func clamp(_ v: Double) -> Double {
    min(1.0, max(0.0, v))
  }
}
