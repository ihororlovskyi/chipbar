import AppKit
import XCTest
@testable import Chipbar

enum SnapshotHelpers {
  static let scale: CGFloat = 2
  static let height: CGFloat = 22

  @MainActor
  static func render(visibility: MetricVisibility, snapshot: Snapshot) -> NSBitmapImageRep {
    let width = StatusBarView.width(for: visibility)
    let view = StatusBarView(frame: NSRect(x: 0, y: 0, width: width, height: height))
    view.appearance = NSAppearance(named: .aqua)
    view.update(visibility: visibility)
    view.update(with: snapshot)

    let pixelsWide = Int((width * scale).rounded())
    let pixelsHigh = Int((height * scale).rounded())
    let bitmap = NSBitmapImageRep(
      bitmapDataPlanes: nil,
      pixelsWide: pixelsWide,
      pixelsHigh: pixelsHigh,
      bitsPerSample: 8,
      samplesPerPixel: 4,
      hasAlpha: true,
      isPlanar: false,
      colorSpaceName: .deviceRGB,
      bytesPerRow: 0,
      bitsPerPixel: 0
    )!
    bitmap.size = NSSize(width: width, height: height)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    view.draw(view.bounds)
    NSGraphicsContext.restoreGraphicsState()

    return bitmap
  }

  static func snapshotsDir(for file: StaticString) -> URL {
    URL(fileURLWithPath: String(describing: file))
      .deletingLastPathComponent()
      .appendingPathComponent("__Snapshots__")
  }

  @MainActor
  static func assertSnapshot(
    visibility: MetricVisibility,
    snapshot: Snapshot,
    named name: String,
    file: StaticString = #file,
    line: UInt = #line
  ) throws {
    try XCTSkipIf(
      ProcessInfo.processInfo.environment["CI"] == "true",
      "pixel-level PNG byte-compare is host-dependent; run locally to verify"
    )
    let bitmap = render(visibility: visibility, snapshot: snapshot)
    guard let actualData = bitmap.representation(using: .png, properties: [:]) else {
      XCTFail("failed to encode actual PNG for \(name)", file: file, line: line)
      return
    }

    let dir = snapshotsDir(for: file)
    let referenceURL = dir.appendingPathComponent("\(name).png")
    let recordMode = ProcessInfo.processInfo.environment["CHIPBAR_SNAPSHOT_RECORD"] == "1"
    let referenceExists = FileManager.default.fileExists(atPath: referenceURL.path)

    if recordMode || !referenceExists {
      try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
      do {
        try actualData.write(to: referenceURL)
      } catch {
        XCTFail("failed to write reference \(referenceURL.path): \(error)", file: file, line: line)
        return
      }
      XCTFail(
        "recorded reference \(name).png at \(referenceURL.path); re-run without CHIPBAR_SNAPSHOT_RECORD to verify",
        file: file,
        line: line
      )
      return
    }

    guard let referenceData = try? Data(contentsOf: referenceURL) else {
      XCTFail("failed to read reference at \(referenceURL.path)", file: file, line: line)
      return
    }

    if actualData != referenceData {
      let actualURL = dir.appendingPathComponent("\(name)-actual.png")
      try? actualData.write(to: actualURL)
      XCTFail(
        "snapshot mismatch for \(name); actual saved at \(actualURL.path). Re-record with CHIPBAR_SNAPSHOT_RECORD=1 if change is intended.",
        file: file,
        line: line
      )
    }
  }
}
