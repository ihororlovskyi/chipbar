import ServiceManagement

enum LoginItemState {
  case enabled
  case disabled
  case requiresApproval
  case unavailable
}

// SMAppService is a system type with no protocol, so a narrow seam keeps the
// state logic testable.
protocol LoginItemService {
  var status: SMAppService.Status { get }
  func register() throws
  func unregister() throws
}

struct SystemLoginItemService: LoginItemService {
  var status: SMAppService.Status { SMAppService.mainApp.status }
  func register() throws { try SMAppService.mainApp.register() }
  func unregister() throws { try SMAppService.mainApp.unregister() }
}

final class LoginItem {
  private let service: LoginItemService

  init(service: LoginItemService = SystemLoginItemService()) {
    self.service = service
  }

  var state: LoginItemState {
    switch service.status {
    case .enabled: return .enabled
    case .requiresApproval: return .requiresApproval
    case .notRegistered: return .disabled
    case .notFound: return .disabled
    @unknown default: return .unavailable
    }
  }

  func setEnabled(_ enabled: Bool) throws {
    // Unknown future statuses are not actionable until their semantics are known.
    guard state != .unavailable else { return }

    if enabled {
      // A stale registration left by a previous install makes register() fail,
      // so clear it first.
      if isRegistered { try? service.unregister() }
      try service.register()
    } else {
      guard isRegistered else { return }
      try service.unregister()
    }
  }

  func openSystemSettings() {
    SMAppService.openSystemSettingsLoginItems()
  }

  private var isRegistered: Bool {
    service.status == .enabled || service.status == .requiresApproval
  }
}
