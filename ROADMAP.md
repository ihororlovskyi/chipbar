# Roadmap

Forward-looking work for ChipBar. Items move from here to `CHANGELOG.md`
once shipped on a tagged release.

## Next patch

- **README screencast / GIF.** Record a short loop of the menu-bar item +
  dropdown (visibility toggles, `Interval`, `About`) and embed it at
  the top of `README.md`. Source recording with `Cmd-Shift-5` (selection +
  10–15 s), convert `.mov` → `.gif` with `ffmpeg` (≤ ~2 MB, ~12 fps).
  Store under `docs/` or `assets/` so the binary doesn't pollute source
  diffs.

## Planned

- **Launch at login.** Use `SMAppService.mainApp` (macOS 13+; our
  deployment target is 14+ so no fallback path is needed). Add a small
  helper exposing `var isEnabled: Bool` — getter returns
  `SMAppService.mainApp.status == .enabled`, setter calls
  `try SMAppService.mainApp.register()` or `.unregister()`. On enable,
  defensively `try? SMAppService.mainApp.unregister()` first when status
  is already `.enabled` to avoid stale-registration errors. Place the
  helper either inline in `Sources/Chipbar/UI/StatusBarController.swift`
  or as its own file under `Sources/Chipbar/Preferences/` if it grows
  beyond ~20 lines. Surface as a new `Launch at Login` menu item under
  the About area in `StatusBarController.buildMenu`, with `.on`/`.off`
  state mirroring the service status and toggled on click. No new
  entitlements required. `SMAppService` only behaves reliably when the
  app lives in `/Applications`, so the manual smoke checklist must add
  a step that drags the built `Chipbar.app` into
  `/Applications` before exercising the toggle. Do not add a
  UserDefaults key for this — the system service is the source of
  truth; reading `SMAppService.mainApp.status` on each menu open is
  cheap.
- Additional metrics: disk, network, temperature, energy.
- **Lightweight graphs / short-term history per metric.** Add a small
  ring-buffer type (`MetricHistory` or similar) under
  `Sources/Chipbar/Metrics/`: fixed capacity (default 60 slots — one
  minute at 1 Hz; scale capacity with refresh interval so the visible
  window stays ≈ 60 s across cadences), `Float?` storage, O(1)
  `add(_:)` with `index = (index + 1) % capacity`, and an internal
  running aggregate (sum) updated incrementally on insert/evict so
  callers never scan the buffer. Expose
  `snapshot() -> [Float?]` returning samples in insertion order for
  rendering. Own one instance per metric inside
  `Sources/Chipbar/Metrics/MetricsSampler.swift` and push each reading
  immediately after the existing `Snapshot` publish; the live readers
  (`CPUReader`, `GPUReader`, `RAMReader`) stay untouched. Render in
  pure AppKit by extending `Sources/Chipbar/UI/StatusBarView.swift` —
  lay a faint sparkline behind the percentage text per cell inside the
  existing `draw(_:)`. Build the path with `NSBezierPath`: start at
  baseline-left, iterate samples mapping `(i, value)` to `(x, y)` with
  `y = rect.maxY - clamp01(value) * rect.maxY`, close back to
  baseline-right, then `fill()` with a low-contrast tint such as
  `NSColor.controlAccentColor.withAlphaComponent(0.18)` so it does not
  fight the foreground digits. Prefer this inline-cell approach over
  an `NSPopover`; only fall back to a popover if the inline tint
  proves too noisy in practice. Hook `NSMenuDelegate.menuWillOpen` and
  `menuDidClose` in `StatusBarController` to flip a
  `historyRenderEnabled` flag and skip the sparkline draw path while
  the dropdown is open — keep `MetricsSampler` running unconditionally
  so the buffer never gaps. History is ephemeral: do NOT persist across
  launches and do NOT add a UserDefaults key; the buffer warms over the
  first minute after launch. Tests: cover `MetricHistory`
  deterministically — insert past capacity, snapshot ordering, and
  aggregate correctness after eviction — under
  `Tests/ChipbarTests/`. The AppKit draw path is now covered by the
  `StatusBarView` snapshot tests shipped in v0.1.3.
- Threshold alerts (notification when a metric crosses a configurable
  ceiling, e.g. CPU > 90% for N seconds).
- Single-row menu-bar layout (`CPU 19%  GPU 49%  MEM 72%`) replacing the
  current two-row label + value cells, per the design example in
  `README.md`.

## Known issues

_None tracked at the moment._

## Future (v0.2.x+)

- **Apple verification (Developer ID + notarization).** Sign releases with a
  real `Developer ID Application` certificate instead of ad-hoc, enable
  hardened runtime (`--options=runtime`), submit the artifact to Apple via
  `xcrun notarytool submit --wait`, then `xcrun stapler staple` it before
  zipping for release. Removes the Gatekeeper "could not verify" dialog on
  first launch for every user (not just brew-cask users), and removes the
  need for `quarantine: false` workarounds. Requires:
  - Apple Developer Program membership (paid, ~$99/year).
  - `Developer ID Application` certificate exported to the CI keychain.
  - Apple ID + app-specific password (or notarytool API key) stored as
    GitHub Actions secrets.
  - `scripts/build-release.sh` updated to use the real identity, and a new
    notarize + staple step before `ditto`.
  - `release.yml` updated to import the certificate, run notarization, and
    keep the existing tap-bump step (the cask can drop `quarantine: false`
    once notarization is in place).

## Out of scope (v0.1.x)

These are intentional non-goals for the current minor series. They can be
revisited in a later major bump if the scope changes.

- Universal binary — `arm64` only; Intel is not supported.
- Localization — UI is English-only by design.
