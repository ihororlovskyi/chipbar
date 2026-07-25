import XCTest
import Combine
@testable import Chipbar

final class PreferencesTests: XCTestCase {
  private var defaults: UserDefaults!
  private var suiteName: String!
  private var cancellables: Set<AnyCancellable> = []

  override func setUp() {
    suiteName = "chipbar-tests-\(UUID().uuidString)"
    defaults = UserDefaults(suiteName: suiteName)!
  }

  override func tearDown() {
    defaults.removePersistentDomain(forName: suiteName)
    cancellables.removeAll()
  }

  func test_defaultIsOneSecondWhenKeyMissing() {
    let prefs = Preferences(defaults: defaults)
    XCTAssertEqual(prefs.refreshIntervalSeconds, 1)
  }

  func test_writeAndReadRoundTrip() {
    let prefs = Preferences(defaults: defaults)
    prefs.refreshIntervalSeconds = 2
    XCTAssertEqual(prefs.refreshIntervalSeconds, 2)

    let prefs2 = Preferences(defaults: defaults)
    XCTAssertEqual(prefs2.refreshIntervalSeconds, 2)
  }

  func test_allowsHalfSecondAndFiveSeconds() {
    let prefs = Preferences(defaults: defaults)
    prefs.refreshIntervalSeconds = 0.5
    XCTAssertEqual(prefs.refreshIntervalSeconds, 0.5)
    prefs.refreshIntervalSeconds = 5
    XCTAssertEqual(prefs.refreshIntervalSeconds, 5)

    let prefs2 = Preferences(defaults: defaults)
    XCTAssertEqual(prefs2.refreshIntervalSeconds, 5)
  }

  func test_invalidValuesFallBackToOne() {
    defaults.set(0.0, forKey: Preferences.refreshIntervalKey)
    XCTAssertEqual(Preferences(defaults: defaults).refreshIntervalSeconds, 1)

    defaults.set(3.0, forKey: Preferences.refreshIntervalKey)
    XCTAssertEqual(Preferences(defaults: defaults).refreshIntervalSeconds, 1)

    defaults.set(-5.0, forKey: Preferences.refreshIntervalKey)
    XCTAssertEqual(Preferences(defaults: defaults).refreshIntervalSeconds, 1)
  }

  func test_migratesLegacyKeyOnFirstRead() {
    defaults.set(2, forKey: Preferences.legacyRefreshIntervalKey)
    XCTAssertNil(defaults.object(forKey: Preferences.refreshIntervalKey))

    let prefs = Preferences(defaults: defaults)
    XCTAssertEqual(prefs.refreshIntervalSeconds, 2)
    XCTAssertEqual(defaults.double(forKey: Preferences.refreshIntervalKey), 2)
  }

  func test_legacyKeyIgnoredWhenValueNoLongerAllowed() {
    defaults.set(3, forKey: Preferences.legacyRefreshIntervalKey)
    XCTAssertEqual(Preferences(defaults: defaults).refreshIntervalSeconds, 1)
  }

  func test_v2KeyTakesPrecedenceOverLegacy() {
    defaults.set(1, forKey: Preferences.legacyRefreshIntervalKey)
    defaults.set(5.0, forKey: Preferences.refreshIntervalKey)
    XCTAssertEqual(Preferences(defaults: defaults).refreshIntervalSeconds, 5)
  }

  func test_publisherEmitsOnChange() {
    let prefs = Preferences(defaults: defaults)
    let exp = expectation(description: "publisher fired")
    var received: [Double] = []

    prefs.refreshIntervalSecondsPublisher
      .dropFirst() // drop initial value
      .sink { value in
        received.append(value)
        if received == [2] { exp.fulfill() }
      }
      .store(in: &cancellables)

    prefs.refreshIntervalSeconds = 2
    wait(for: [exp], timeout: 1.0)
    XCTAssertEqual(received, [2])
  }

  func test_metricVisibilityDefaultsHideRAM() {
    let prefs = Preferences(defaults: defaults)
    XCTAssertEqual(prefs.metricVisibility, .defaults)
    XCTAssertEqual(prefs.metricVisibility, MetricVisibility(cpu: true, gpu: true, ram: false))
  }

  func test_existingRAMVisibilityIsPreserved() {
    defaults.set(true, forKey: Preferences.showRAMKey)
    XCTAssertTrue(Preferences(defaults: defaults).metricVisibility.ram)
  }

  func test_metricVisibilityRoundTrip() {
    let prefs = Preferences(defaults: defaults)
    XCTAssertTrue(prefs.setMetricVisible(.ram, true))
    XCTAssertTrue(prefs.setMetricVisible(.gpu, false))
    XCTAssertEqual(prefs.metricVisibility.gpu, false)
    XCTAssertEqual(prefs.metricVisibility.cpu, true)
    XCTAssertEqual(prefs.metricVisibility.ram, true)

    let prefs2 = Preferences(defaults: defaults)
    XCTAssertEqual(prefs2.metricVisibility.gpu, false)
    XCTAssertEqual(prefs2.metricVisibility.cpu, true)
    XCTAssertEqual(prefs2.metricVisibility.ram, true)
  }

  func test_cannotHideLastVisibleMetric() {
    let prefs = Preferences(defaults: defaults)
    XCTAssertTrue(prefs.setMetricVisible(.gpu, false))
    XCTAssertTrue(prefs.setMetricVisible(.ram, false))
    XCTAssertFalse(prefs.setMetricVisible(.cpu, false))
    XCTAssertEqual(prefs.metricVisibility.cpu, true)
  }

  func test_visibilityFallsBackWhenStoredStateIsAllOff() {
    defaults.set(false, forKey: Preferences.showCPUKey)
    defaults.set(false, forKey: Preferences.showGPUKey)
    defaults.set(false, forKey: Preferences.showRAMKey)
    XCTAssertEqual(Preferences(defaults: defaults).metricVisibility, .defaults)
  }
}
