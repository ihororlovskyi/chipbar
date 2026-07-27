import Foundation
import Darwin

protocol CPUReading {
  /// Returns CPU utilisation in the range 0.0...1.0.
  func sample() -> Double
}

struct CPUTicks: Equatable {
  let user: UInt64
  let system: UInt64
  let idle: UInt64
  let nice: UInt64

  var busy: UInt64 { user &+ system &+ nice }
  var total: UInt64 { busy &+ idle }
}

final class CPUReader: CPUReading {
  private let provider: () -> CPUTicks
  private var previous: CPUTicks?

  init(provider: @escaping () -> CPUTicks = CPUReader.readHostTicks) {
    self.provider = provider
  }

  func sample() -> Double {
    let current = provider()
    defer { previous = current }
    guard let prev = previous else { return 0.0 }

    let busyDelta = current.busy &- prev.busy
    let totalDelta = current.total &- prev.total
    guard totalDelta > 0 else { return 0.0 }

    return Double(busyDelta) / Double(totalDelta)
  }

  static func readHostTicks() -> CPUTicks {
    var info = host_cpu_load_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
    let host = mach_host_self()

    let kr = withUnsafeMutablePointer(to: &info) { ptr -> kern_return_t in
      ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPtr in
        host_statistics(host, HOST_CPU_LOAD_INFO, reboundPtr, &count)
      }
    }

    guard kr == KERN_SUCCESS else {
      return CPUTicks(user: 0, system: 0, idle: 0, nice: 0)
    }

    return CPUTicks(
      user: UInt64(info.cpu_ticks.0),
      system: UInt64(info.cpu_ticks.1),
      idle: UInt64(info.cpu_ticks.2),
      nice: UInt64(info.cpu_ticks.3)
    )
  }
}
