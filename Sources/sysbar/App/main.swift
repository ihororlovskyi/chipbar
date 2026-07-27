import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private let preferences = Preferences()
  private var sampler: MetricsSampler!
  private var controller: StatusBarController!
  private var samplerTask: Task<Void, Error>?
  private var snapshotTask: Task<Void, Never>?
  private var cancellables: Set<AnyCancellable> = []

  func applicationDidFinishLaunching(_ notification: Notification) {
    sampler = MetricsSampler(
      cpu: CPUReader(),
      gpu: GPUReader(),
      ram: RAMReader(),
      initialInterval: preferences.refreshIntervalSeconds
    )
    controller = StatusBarController(preferences: preferences)

    samplerTask = Task { try await sampler.start() }
    snapshotTask = Task { [weak self] in
      guard let self else { return }
      for await snap in sampler.snapshots {
        await MainActor.run { self.controller.update(with: snap) }
      }
    }

    preferences.refreshIntervalSecondsPublisher
      .removeDuplicates()
      .sink { [weak self] interval in
        guard let self else { return }
        Task { await self.sampler.setInterval(interval) }
        self.controller.refreshIntervalChecks()
      }
      .store(in: &cancellables)
  }

  func applicationWillTerminate(_ notification: Notification) {
    snapshotTask?.cancel()
    samplerTask?.cancel()
  }
}

MainActor.assumeIsolated {
  let app = NSApplication.shared
  let delegate = AppDelegate()
  app.delegate = delegate
  app.setActivationPolicy(.accessory)
  app.run()
}
