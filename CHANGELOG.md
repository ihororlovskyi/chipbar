# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

_No unreleased changes._

See [ROADMAP.md](ROADMAP.md) for planned work and explicit non-goals.

## [0.1.3] — 2026-05-20

### Added

- Real `.icns` app icon bundled at `Sources/Chipbar/Resources/AppIcon.icns` (Mono Light variant: silver squircle, dark chip with `Chipbar` wordmark, monochrome CPU / GPU / RAM traces). Wired via `CFBundleIconFile` in `Info.plist` and rendered at every macOS size (16 / 32 / 128 / 256 / 512, 1x + 2x) so Finder / Dock / Cmd-Tab / Launchpad / "Open With" / Spotlight / About panel all show real artwork instead of the generic placeholder. The menu-bar item stays text-only — by design. README banner uses the animated hero SVG (`assets/img/chipbar-hero-animated.svg`).
- Refresh-interval picker exposes four cadences: `0.5 sec`, `1 sec` (default), `2 sec`, `5 sec`. UserDefaults key bumped from `chipbar.refreshIntervalSeconds` (`Int`) to `chipbar.refreshIntervalSecondsV2` (`Double`); the old value is read once and migrated on first launch so v0.1.2 users keep their cadence. Submenu title renamed `Update every` → `Interval`.
- Pixel-level `StatusBarView` snapshot tests under `Tests/ChipbarTests/__Snapshots__/` covering 1-, 2-, 3-cell layouts × representative CPU / GPU / RAM percentages. Replaces the visual portion of the manual smoke checklist; AppKit views are drawn offscreen into `NSImage` and byte-compared against reference PNGs.

### Changed

- Full rebrand back to `Chipbar`. The v0.1.1 / v0.1.2 path of migrating to `mchip` is reverted: app name, bundle, target, scheme, folders, scripts, CI artifacts, and Homebrew cask are all `Chipbar` / `chipbar` again. `CFBundleName` and `CFBundleDisplayName` are now a literal `Chipbar` (was `mchip-v$(MARKETING_VERSION)`); the release bundle is `Chipbar.app` (was `mchip-v<version>.app`); the release zip is `Chipbar-<version>.zip` (was `mchip-<version>.zip`); the GitHub release title is `Chipbar <tag>` (was `mchip <tag>`); the Homebrew cask in [`ihororlovskyi/homebrew-tap`](https://github.com/ihororlovskyi/homebrew-tap) is `chipbar` (was `mchip`). User-visible menu strings now read `Chipbar • v<version> • <dd MMM yy>` and `Quit Chipbar`. `CFBundleIdentifier` stays `com.ihororlovskyi.chipbar` to preserve LaunchServices identity and granted permissions; UserDefaults keys (`chipbar.show.*`, `chipbar.refreshIntervalSecondsV2`) also stay so v0.1.2 users keep their settings. Migration for existing users: `brew uninstall --cask mchip && brew install --cask chipbar` once; manual installs need to drag `mchip-v0.1.2.app` to Trash and install the new `Chipbar.app`.
- Internal rename to match the brand: Xcode project `mchip.xcodeproj` → `Chipbar.xcodeproj`, target / scheme `mchip` → `Chipbar`, source directory `Sources/mchip/` → `Sources/Chipbar/`, test target `mchipTests` → `ChipbarTests` (folder `Tests/mchipTests/` → `Tests/ChipbarTests/`), archive path `build/mchip.xcarchive` → `build/Chipbar.xcarchive`, binary inside the bundle `Contents/MacOS/mchip` → `Contents/MacOS/Chipbar`. `project.yml` regenerated via `xcodegen generate`.
- GitHub repository renamed `ihororlovskyi/mchip` → `ihororlovskyi/chipbar`. In-tree URL references updated: `StatusBarController.repositoryURL` (`About → GitHub` row) and `CHANGELOG.md` compare/release links now point at the canonical new slug. GitHub still serves the old URL via 301 redirect.
- `actions/checkout` bumped from `v4` to `v5` in `.github/workflows/release.yml` and `ci.yml`, ahead of GitHub's Node.js 20 deprecation.
- About submenu collapsed to a single inline info row `Chipbar • v<version> • <dd MMM yy>` above the clickable `GitHub` row. No "Leave feedback" CTA; the `GitHub` row is the only link out.
- `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` bumped to `0.1.3`.

## [0.1.2] — 2026-05-18

### Changed

- RAM cell is now hidden by default on fresh installs (`chipbar.show.ram` defaults to `false`). The menu-bar item ships as a two-cell `CPU` + `GPU` layout out of the box; users who already persisted a visibility value keep it. The all-off fallback also lands on CPU + GPU on, RAM off instead of re-enabling all three.
- In-tree references to the GitHub repository slug updated from `ihororlovskyi/chipbar` to `ihororlovskyi/mchip` to match the repository rename: `About → GitHub` row (`StatusBarController.repositoryURL`) and `CHANGELOG.md` compare/release links. GitHub still serves the old URL via 301 redirect, but the in-tree links now point at the canonical location.
- Homebrew cask renamed `chipbar` → `mchip` in [`ihororlovskyi/homebrew-tap`](https://github.com/ihororlovskyi/homebrew-tap) (`Casks/chipbar.rb` → `Casks/mchip.rb`; internal `cask`/`name`/`url`/`homepage` updated to the new slug). New install command is `brew install --cask mchip`; the cask `url` stanza now also sets `quarantine: false`, so future installs skip the Gatekeeper "Apple could not verify…" prompt on ad-hoc-signed builds. Users on the old cask: run `brew uninstall --cask chipbar && brew install --cask mchip` once to migrate.
- Release workflow points at the renamed cask (`homebrew-tap/Casks/mchip.rb`, commit message `mchip: <version>`) and the GitHub release title is now `mchip <tag>` instead of `Chip Bar <tag>`.
- The release `.app` bundle is now named `mchip-v<version>.app` (e.g. `mchip-v0.1.2.app`) instead of `Chipbar.app`. `CFBundleName` and `CFBundleDisplayName` resolve to the same string at build time via `mchip-v$(MARKETING_VERSION)`. `CFBundleIdentifier` stays `com.ihororlovskyi.chipbar`, so LaunchServices treats this as the same app and previously granted permissions are preserved. The cask now declares `app "mchip-v#{version}.app"`. Users on `brew install --cask mchip` will see the previous `/Applications/Chipbar.app` removed and `mchip-v0.1.2.app` installed in its place automatically on `brew upgrade`; manual installs need to drag the old `Chipbar.app` to Trash themselves. The Xcode target, scheme, and the binary inside the bundle (`Contents/MacOS/Chipbar`) are still called `Chipbar` — that rename is tracked for v0.1.3.
- `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` bumped to `0.1.2`.

## [0.1.1] — 2026-05-16

### Added

- Per-metric visibility toggles: `CPU` / `GPU` / `RAM` rows in the dropdown now act as checkboxes that hide or show the corresponding cell in the menu-bar item. Persisted as `chipbar.show.cpu` / `chipbar.show.gpu` / `chipbar.show.ram`. The last visible metric cannot be turned off; if all three are stored as `false`, the app falls back to showing all on next launch.
- `About` submenu in the dropdown, listing the app name (`mchip`), version (`v<CFBundleShortVersionString>`), build date (executable `mtime`, formatted `dd MMM yy`), and a `GitHub` entry that opens the repository (`https://github.com/ihororlovskyi/mchip`) in the default browser.

### Changed

- User-facing app name is now `mchip` (`CFBundleDisplayName`); menu quit item reads `Quit mchip`. Bundle identifier, scheme, target name, scripts, cask, and `UserDefaults` keys remain `chipbar`/`Chipbar` — no migration needed.
- Status-bar item width is now derived from the number of visible metrics instead of a fixed three-cell width.
- `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` bumped to `0.1.1`.
- `GPUReader` rewritten on top of public IOKit: enumerates `IOAccelerator` services and reads `Device Utilization %` from each one's `PerformanceStatistics` dictionary, taking the maximum across services. The private `libIOReport.dylib` `dlopen` bridge (`IOReportBridge`, `IOReportCopyChannelsInGroup` / `IOReportCreateSubscription` / `IOReportCreateSamples` / `IOReportCreateSamplesDelta`, `GPU Stats` channel filtering, `GPU Idle Residency` parsing, delta-based residency math, `primed`/`previousActive`/`previousTotal` state) is gone. Works on Apple Silicon (AGX) and Intel + AMD/NVIDIA discrete GPUs alike.

### Fixed

- GPU usage rendering on Apple Silicon: previously always reported `0%` under load. The new `IOAccelerator` / `Device Utilization %` path returns live utilisation.

## [0.1.0] — 2026-05-16

Initial release.

### Added

- macOS menu bar app showing CPU / GPU / RAM utilisation, refreshed every 1s or 2s.
- `CPUReader` using `host_cpu_load_info`.
- `GPUReader` using the private IOReport framework (`/usr/lib/libIOReport.dylib`), with fault-tolerant fallback to a zero reader when the API is unavailable (e.g. headless CI runners).
- `RAMReader` using `host_statistics64`.
- `MetricsSampler` actor with reschedulable interval.
- `Preferences` wrapper over UserDefaults with a publisher for refresh-interval changes.
- `StatusBarController` + `StatusBarView` two-row icon + percentage rendering with a click-through menu (interval picker + Quit).
- XcodeGen `project.yml` (arm64, manual ad-hoc signing).
- `xcodebuild` test suite (17 tests covering CPU, GPU, RAM, Sampler, Preferences, Snapshot).
- GitHub Actions: `ci` (tests on PR / push to main, `macos-15` runner) and `release` (tag-triggered build, sign, zip, GitHub release, Homebrew cask bump).
- `scripts/build-release.sh` — archive, export, ad-hoc sign, zip; stamps `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` into `Info.plist`.
- `scripts/update-cask.sh` — bumps `version` / `sha256` in the tap cask.
- Homebrew tap at [`ihororlovskyi/homebrew-tap`](https://github.com/ihororlovskyi/homebrew-tap), installable via `brew install --cask chipbar`.

[Unreleased]: https://github.com/ihororlovskyi/chipbar/compare/v0.1.3...HEAD
[0.1.3]: https://github.com/ihororlovskyi/chipbar/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/ihororlovskyi/chipbar/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/ihororlovskyi/chipbar/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/ihororlovskyi/chipbar/releases/tag/v0.1.0
