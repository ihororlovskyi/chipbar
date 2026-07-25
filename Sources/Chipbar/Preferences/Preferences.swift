import Foundation
import Combine

struct MetricVisibility: Equatable, Sendable {
  var cpu: Bool
  var gpu: Bool
  var ram: Bool

  static let allOn = MetricVisibility(cpu: true, gpu: true, ram: true)
  static let defaults = MetricVisibility(cpu: true, gpu: true, ram: false)

  var visibleCount: Int {
    (cpu ? 1 : 0) + (gpu ? 1 : 0) + (ram ? 1 : 0)
  }
}

final class Preferences {
  static let legacyRefreshIntervalKey = "chipbar.refreshIntervalSeconds"
  static let refreshIntervalKey = "chipbar.refreshIntervalSecondsV2"
  static let allowedIntervals: [Double] = [0.5, 1, 2, 5]
  static let defaultInterval: Double = 1

  static let showCPUKey = "chipbar.show.cpu"
  static let showGPUKey = "chipbar.show.gpu"
  static let showRAMKey = "chipbar.show.ram"

  private let defaults: UserDefaults
  private let intervalSubject: CurrentValueSubject<Double, Never>
  private let visibilitySubject: CurrentValueSubject<MetricVisibility, Never>

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults

    let initialInterval = Self.loadInterval(defaults: defaults)
    self.intervalSubject = CurrentValueSubject(initialInterval)

    let initialVisibility = MetricVisibility(
      cpu: Self.loadFlag(defaults: defaults, key: Self.showCPUKey, default: MetricVisibility.defaults.cpu),
      gpu: Self.loadFlag(defaults: defaults, key: Self.showGPUKey, default: MetricVisibility.defaults.gpu),
      ram: Self.loadFlag(defaults: defaults, key: Self.showRAMKey, default: MetricVisibility.defaults.ram)
    )
    self.visibilitySubject = CurrentValueSubject(
      initialVisibility.visibleCount == 0 ? .defaults : initialVisibility
    )
  }

  var refreshIntervalSeconds: Double {
    get { intervalSubject.value }
    set {
      let value = Self.isAllowed(newValue) ? newValue : Self.defaultInterval
      defaults.set(value, forKey: Self.refreshIntervalKey)
      intervalSubject.send(value)
    }
  }

  var refreshIntervalSecondsPublisher: AnyPublisher<Double, Never> {
    intervalSubject.eraseToAnyPublisher()
  }

  var metricVisibility: MetricVisibility {
    visibilitySubject.value
  }

  var metricVisibilityPublisher: AnyPublisher<MetricVisibility, Never> {
    visibilitySubject.eraseToAnyPublisher()
  }

  @discardableResult
  func setMetricVisible(_ metric: Metric, _ visible: Bool) -> Bool {
    var next = visibilitySubject.value
    switch metric {
    case .cpu: next.cpu = visible
    case .gpu: next.gpu = visible
    case .ram: next.ram = visible
    }
    if next.visibleCount == 0 { return false }
    defaults.set(next.cpu, forKey: Self.showCPUKey)
    defaults.set(next.gpu, forKey: Self.showGPUKey)
    defaults.set(next.ram, forKey: Self.showRAMKey)
    visibilitySubject.send(next)
    return true
  }

  enum Metric {
    case cpu, gpu, ram
  }

  private static func isAllowed(_ value: Double) -> Bool {
    allowedIntervals.contains(value)
  }

  private static func loadInterval(defaults: UserDefaults) -> Double {
    if let raw = defaults.object(forKey: refreshIntervalKey) as? Double, isAllowed(raw) {
      return raw
    }
    if let legacyRaw = defaults.object(forKey: legacyRefreshIntervalKey) as? Int {
      let migrated = Double(legacyRaw)
      if isAllowed(migrated) {
        defaults.set(migrated, forKey: refreshIntervalKey)
        return migrated
      }
    }
    return defaultInterval
  }

  private static func loadFlag(defaults: UserDefaults, key: String, default fallback: Bool) -> Bool {
    if defaults.object(forKey: key) == nil { return fallback }
    return defaults.bool(forKey: key)
  }
}
