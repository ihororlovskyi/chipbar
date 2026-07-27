import AppKit
import Combine

@MainActor
final class StatusBarController: NSObject {
  static let repositoryURL = URL(string: "https://github.com/ihororlovskyi/sysbar")!

  private let statusItem: NSStatusItem
  private let view: StatusBarView
  private let menu: NSMenu
  private let cpuItem = NSMenuItem(title: "CPU  —", action: nil, keyEquivalent: "")
  private let gpuItem = NSMenuItem(title: "GPU  —", action: nil, keyEquivalent: "")
  private let ramItem = NSMenuItem(title: "RAM  —", action: nil, keyEquivalent: "")
  private let halfSecondItem = NSMenuItem(title: "0.5 sec", action: nil, keyEquivalent: "")
  private let oneSecondItem = NSMenuItem(title: "1 sec", action: nil, keyEquivalent: "")
  private let twoSecondsItem = NSMenuItem(title: "2 sec", action: nil, keyEquivalent: "")
  private let fiveSecondsItem = NSMenuItem(title: "5 sec", action: nil, keyEquivalent: "")
  private let loginItemMenuItem = NSMenuItem(title: "Launch at Login", action: nil, keyEquivalent: "")
  private let loginItem = LoginItem()
  private let preferences: Preferences

  init(preferences: Preferences) {
    self.preferences = preferences
    let initialWidth = StatusBarView.width(for: preferences.metricVisibility)
    self.statusItem = NSStatusBar.system.statusItem(withLength: initialWidth)
    self.view = StatusBarView(frame: NSRect(x: 0, y: 0, width: initialWidth, height: NSStatusBar.system.thickness))
    self.menu = NSMenu(title: "sysbar")
    super.init()

    statusItem.button?.addSubview(view)
    view.frame = statusItem.button?.bounds ?? view.frame
    view.autoresizingMask = [.width, .height]
    view.update(visibility: preferences.metricVisibility)

    buildMenu()
    statusItem.menu = menu
    menu.delegate = self
    refreshIntervalChecks()
    refreshVisibilityChecks()
    refreshLoginItemState()
  }

  func update(with snapshot: Snapshot) {
    view.update(with: snapshot)
    cpuItem.title = "CPU  \(percent(snapshot.cpu))"
    gpuItem.title = "GPU  \(percent(snapshot.gpu))"
    ramItem.title = "RAM  \(percent(snapshot.ram))"
  }

  func refreshIntervalChecks() {
    let current = preferences.refreshIntervalSeconds
    halfSecondItem.state = current == 0.5 ? .on : .off
    oneSecondItem.state = current == 1 ? .on : .off
    twoSecondsItem.state = current == 2 ? .on : .off
    fiveSecondsItem.state = current == 5 ? .on : .off
  }

  func refreshVisibilityChecks() {
    let visibility = preferences.metricVisibility
    cpuItem.state = visibility.cpu ? .on : .off
    gpuItem.state = visibility.gpu ? .on : .off
    ramItem.state = visibility.ram ? .on : .off
    view.update(visibility: visibility)
    let width = StatusBarView.width(for: visibility)
    statusItem.length = width
    view.frame = statusItem.button?.bounds ?? NSRect(x: 0, y: 0, width: width, height: NSStatusBar.system.thickness)
  }

  func refreshLoginItemState() {
    switch loginItem.state {
    case .enabled:
      loginItemMenuItem.title = "Launch at Login"
      loginItemMenuItem.state = .on
      loginItemMenuItem.isEnabled = true
    case .disabled:
      loginItemMenuItem.title = "Launch at Login"
      loginItemMenuItem.state = .off
      loginItemMenuItem.isEnabled = true
    case .requiresApproval:
      loginItemMenuItem.title = "Launch at Login — Approval Required"
      loginItemMenuItem.state = .mixed
      loginItemMenuItem.isEnabled = true
    case .unavailable:
      loginItemMenuItem.title = "Launch at Login"
      loginItemMenuItem.state = .off
      loginItemMenuItem.isEnabled = false
    }
  }

  private func buildMenu() {
    cpuItem.target = self
    cpuItem.action = #selector(toggleCPU)
    gpuItem.target = self
    gpuItem.action = #selector(toggleGPU)
    ramItem.target = self
    ramItem.action = #selector(toggleRAM)

    menu.addItem(cpuItem)
    menu.addItem(gpuItem)
    menu.addItem(ramItem)
    menu.addItem(.separator())

    let intervalParent = NSMenuItem(title: "Interval", action: nil, keyEquivalent: "")
    let submenu = NSMenu(title: "Interval")
    halfSecondItem.target = self
    halfSecondItem.action = #selector(selectHalfSecond)
    oneSecondItem.target = self
    oneSecondItem.action = #selector(selectOneSecond)
    twoSecondsItem.target = self
    twoSecondsItem.action = #selector(selectTwoSeconds)
    fiveSecondsItem.target = self
    fiveSecondsItem.action = #selector(selectFiveSeconds)
    submenu.addItem(halfSecondItem)
    submenu.addItem(oneSecondItem)
    submenu.addItem(twoSecondsItem)
    submenu.addItem(fiveSecondsItem)
    intervalParent.submenu = submenu
    menu.addItem(intervalParent)

    loginItemMenuItem.target = self
    loginItemMenuItem.action = #selector(toggleLaunchAtLogin)
    menu.addItem(loginItemMenuItem)

    let about = NSMenuItem(title: "About sysbar", action: #selector(showAbout), keyEquivalent: "")
    about.target = self
    menu.addItem(about)

    menu.addItem(.separator())
    let quit = NSMenuItem(title: "Quit sysbar", action: #selector(quitApp), keyEquivalent: "q")
    quit.target = self
    menu.addItem(quit)
  }

  @objc private func showAbout() {
    let fallback = Self.executableModificationDate
    let stamped = Bundle.main.infoDictionary?[AboutInfo.releaseDateKey] as? String
    let date = AboutInfo.releaseDate(plistValue: stamped, fallback: fallback)

    // LSUIElement apps are not active by default; without this the panel opens
    // behind whatever window has focus.
    NSApp.activate(ignoringOtherApps: true)
    NSApplication.shared.orderFrontStandardAboutPanel(options: [
      .applicationName: "sysbar",
      .applicationVersion: Self.appVersion,
      .version: Self.buildVersion,
      .credits: AboutInfo.credits(dateText: AboutInfo.format(date), repositoryURL: Self.repositoryURL),
    ])
  }

  private static var appVersion: String {
    (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0.0"
  }

  private static var buildVersion: String {
    (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "0"
  }

  private static var executableModificationDate: Date {
    let url = Bundle.main.executableURL ?? Bundle.main.bundleURL
    let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
    return (attrs?[.modificationDate] as? Date) ?? Date()
  }

  @objc private func toggleCPU() { toggle(.cpu, item: cpuItem) }
  @objc private func toggleGPU() { toggle(.gpu, item: gpuItem) }
  @objc private func toggleRAM() { toggle(.ram, item: ramItem) }

  private func toggle(_ metric: Preferences.Metric, item: NSMenuItem) {
    let nextVisible = item.state != .on
    if preferences.setMetricVisible(metric, nextVisible) {
      refreshVisibilityChecks()
    } else {
      NSSound.beep()
    }
  }

  @objc private func selectHalfSecond() {
    preferences.refreshIntervalSeconds = 0.5
    refreshIntervalChecks()
  }

  @objc private func selectOneSecond() {
    preferences.refreshIntervalSeconds = 1
    refreshIntervalChecks()
  }

  @objc private func selectTwoSeconds() {
    preferences.refreshIntervalSeconds = 2
    refreshIntervalChecks()
  }

  @objc private func selectFiveSeconds() {
    preferences.refreshIntervalSeconds = 5
    refreshIntervalChecks()
  }

  @objc private func toggleLaunchAtLogin() {
    // Already registered but unapproved: re-registering does nothing useful,
    // the user has to approve it in System Settings.
    if loginItem.state == .requiresApproval {
      loginItem.openSystemSettings()
      return
    }

    do {
      try loginItem.setEnabled(loginItem.state != .enabled)
    } catch {
      presentLoginItemError(error)
    }
    refreshLoginItemState()
  }

  private func presentLoginItemError(_ error: Error) {
    let alert = NSAlert()
    alert.messageText = "Could not change the login item"
    alert.informativeText = """
      \(error.localizedDescription)

      Registration usually fails when the app runs from outside /Applications. \
      Move sysbar.app to /Applications and try again.
      """
    alert.alertStyle = .warning
    alert.runModal()
  }

  @objc private func quitApp() {
    NSApp.terminate(nil)
  }

  private func percent(_ value: Double) -> String {
    "\(Int((value * 100).rounded()))%"
  }
}

extension StatusBarController: NSMenuDelegate {
  func menuWillOpen(_ menu: NSMenu) {
    refreshLoginItemState()
  }
}
