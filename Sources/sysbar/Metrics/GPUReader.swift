import Foundation
import IOKit

protocol GPUReading {
  /// Returns GPU utilisation in the range 0.0...1.0.
  func sample() -> Double
}

final class MockGPUReader: GPUReading {
  private let samples: () -> Double
  init(samples: @escaping () -> Double) { self.samples = samples }
  func sample() -> Double { samples() }
}

/// Reads GPU utilisation from the public IOKit registry. Same approach iStat Menus,
/// Stats.app, asitop, etc. use: enumerate `IOAccelerator` services and pull
/// `Device Utilization %` out of each one's `PerformanceStatistics` dictionary.
/// Works for Apple Silicon (AGX) and Intel + AMD/NVIDIA discrete GPUs alike.
final class GPUReader: GPUReading {
  func sample() -> Double {
    var iter: io_iterator_t = 0
    let matching = IOServiceMatching("IOAccelerator")
    guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS else {
      return 0
    }
    defer { IOObjectRelease(iter) }

    var maxUtilization: Double = 0
    while true {
      let service = IOIteratorNext(iter)
      if service == 0 { break }
      defer { IOObjectRelease(service) }

      var unmanagedProps: Unmanaged<CFMutableDictionary>?
      guard IORegistryEntryCreateCFProperties(service, &unmanagedProps, kCFAllocatorDefault, 0) == KERN_SUCCESS,
            let props = unmanagedProps?.takeRetainedValue() as? [String: Any],
            let perf = props["PerformanceStatistics"] as? [String: Any] else { continue }

      if let util = perf["Device Utilization %"] as? NSNumber {
        maxUtilization = max(maxUtilization, util.doubleValue / 100.0)
      }
    }
    return min(1.0, max(0.0, maxUtilization))
  }
}
