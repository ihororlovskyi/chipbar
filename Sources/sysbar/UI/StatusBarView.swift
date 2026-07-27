import AppKit

@MainActor
final class StatusBarView: NSView {
  static let cellWidth: CGFloat = 110.0 / 3.0
  static let preferredWidth: CGFloat = cellWidth * 3
  static let minimumWidth: CGFloat = 8

  private var snapshot: Snapshot = .zero
  private var visibility: MetricVisibility = .allOn
  private let labelFont = NSFont.systemFont(ofSize: 9, weight: .medium)
  private let valueFont = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)

  override var intrinsicContentSize: NSSize {
    NSSize(width: Self.width(for: visibility), height: NSStatusBar.system.thickness)
  }

  static func width(for visibility: MetricVisibility) -> CGFloat {
    let count = CGFloat(visibility.visibleCount)
    return count == 0 ? minimumWidth : cellWidth * count
  }

  func update(with snapshot: Snapshot) {
    self.snapshot = snapshot
    needsDisplay = true
  }

  func update(visibility: MetricVisibility) {
    self.visibility = visibility
    invalidateIntrinsicContentSize()
    needsDisplay = true
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    let visibleCells: [(String, Double)] = [
      ("CPU", snapshot.cpu, visibility.cpu),
      ("GPU", snapshot.gpu, visibility.gpu),
      ("RAM", snapshot.ram, visibility.ram),
    ].compactMap { $0.2 ? ($0.0, $0.1) : nil }

    guard !visibleCells.isEmpty else { return }

    let cellWidth = bounds.width / CGFloat(visibleCells.count)
    for (index, cell) in visibleCells.enumerated() {
      let frame = NSRect(
        x: CGFloat(index) * cellWidth,
        y: 0,
        width: cellWidth,
        height: bounds.height
      )
      drawCell(label: cell.0, value: cell.1, in: frame)
    }
  }

  private func drawCell(label: String, value: Double, in rect: NSRect) {
    let percent = Int((value * 100).rounded())

    let labelAttrs: [NSAttributedString.Key: Any] = [
      .font: labelFont,
      .foregroundColor: NSColor.labelColor,
    ]
    let labelAS = NSAttributedString(string: label, attributes: labelAttrs)
    let labelSize = labelAS.size()

    let valueAttrs: [NSAttributedString.Key: Any] = [
      .font: valueFont,
      .foregroundColor: NSColor.labelColor,
    ]
    let valueAS = NSAttributedString(string: "\(percent)%", attributes: valueAttrs)
    let valueSize = valueAS.size()

    let spacing: CGFloat = 0
    let totalHeight = labelSize.height + spacing + valueSize.height
    let originY = (rect.height - totalHeight) / 2

    let labelRect = NSRect(
      x: rect.midX - labelSize.width / 2,
      y: originY + valueSize.height + spacing,
      width: labelSize.width,
      height: labelSize.height
    )
    labelAS.draw(in: labelRect)

    let valueRect = NSRect(
      x: rect.midX - valueSize.width / 2,
      y: originY,
      width: valueSize.width,
      height: valueSize.height
    )
    valueAS.draw(in: valueRect)
  }
}
