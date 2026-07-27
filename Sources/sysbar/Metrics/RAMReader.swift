import Foundation
import Darwin

protocol RAMReading {
  /// Returns RAM utilisation in the range 0.0...1.0.
  func sample() -> Double
}

struct VMSample: Equatable {
  let pageSize: UInt64
  let totalPages: UInt64
  let internalPages: UInt64
  let wiredPages: UInt64
  let compressedPages: UInt64
}

final class RAMReader: RAMReading {
  private let provider: () -> VMSample

  init(provider: @escaping () -> VMSample = RAMReader.readHostSample) {
    self.provider = provider
  }

  func sample() -> Double {
    let s = provider()
    guard s.totalPages > 0 else { return 0.0 }
    let used = s.internalPages &+ s.wiredPages &+ s.compressedPages
    return Double(used) / Double(s.totalPages)
  }

  static func readHostSample() -> VMSample {
    var info = vm_statistics64_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
    let host = mach_host_self()

    let kr = withUnsafeMutablePointer(to: &info) { ptr -> kern_return_t in
      ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPtr in
        host_statistics64(host, HOST_VM_INFO64, reboundPtr, &count)
      }
    }
    guard kr == KERN_SUCCESS else {
      return VMSample(pageSize: 16_384, totalPages: 0, internalPages: 0, wiredPages: 0, compressedPages: 0)
    }

    var pageSize: vm_size_t = 0
    host_page_size(host, &pageSize)

    let physBytes = ProcessInfo.processInfo.physicalMemory
    let totalPages = pageSize > 0 ? physBytes / UInt64(pageSize) : 0

    return VMSample(
      pageSize: UInt64(pageSize),
      totalPages: totalPages,
      internalPages: UInt64(info.internal_page_count),
      wiredPages: UInt64(info.wire_count),
      compressedPages: UInt64(info.compressor_page_count)
    )
  }
}
