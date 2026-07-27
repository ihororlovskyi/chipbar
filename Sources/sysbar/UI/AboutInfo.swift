import AppKit

// Pure formatting for the About panel. Takes plain values, never reads Bundle or
// FileManager itself, so every branch is unit-testable.
enum AboutInfo {
  static let releaseDateKey = "SysbarReleaseDate"

  static func releaseDate(plistValue: String?, fallback: Date) -> Date {
    guard let plistValue, !plistValue.isEmpty, let parsed = parser.date(from: plistValue) else {
      return fallback
    }
    return parsed
  }

  static func format(_ date: Date) -> String {
    formatter.string(from: date)
  }

  static func credits(dateText: String, repositoryURL: URL) -> NSAttributedString {
    let credits = NSMutableAttributedString(
      string: "Released \(dateText)\n",
      attributes: [.font: NSFont.systemFont(ofSize: 11)]
    )
    credits.append(NSAttributedString(
      string: "GitHub",
      attributes: [
        .font: NSFont.systemFont(ofSize: 11),
        .link: repositoryURL,
      ]
    ))
    return credits
  }

  // Date-only values need a pinned calendar and time zone, otherwise the rendered
  // day shifts for users outside UTC. Strict parsing rejects impossible dates
  // instead of rolling them over.
  private static let parser: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.isLenient = false
    return formatter
  }()

  private static let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "dd MMM yy"
    return formatter
  }()
}
