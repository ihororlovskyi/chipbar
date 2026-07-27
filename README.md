# sysbar

sysbar - is a tiny macos monitor of apple silicon chip process

## Design
```md
CPU  GPU  RAM
 4%  20%  25%
```

## Install

You can install it from my homebrew tap
```zsh
brew tap ihororlovskyi/tap
brew trust --cask ihororlovskyi/tap/sysbar
brew install --cask sysbar
```
Or you can download the latest release manually:
1. Download and extract the zip file from the latest GitHub release.
2. Drag `sysbar.app` into your computer's Applications folder.

For both Homebrew and manual installations, first launch sysbar via `/Applications` → right-click `sysbar.app` → "Open".

## Update

```zsh
brew update
brew upgrade --cask sysbar
```

## Uninstall

```zsh
brew uninstall --cask sysbar
```

See [CHANGELOG.md](CHANGELOG.md) for release notes.

Have fun ;)
