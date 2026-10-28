# Contributing to Summwatch

Thanks for your interest! This guide covers what we accept, how to set up, and how changes get merged.

## Ground rules: what we will not merge

Summwatch must stay within Riot's [third-party developer policies](https://developer.riotgames.com/policies/general) and must never put a player's account at risk. Pull requests that add any of the following will be closed, however well they're written:

- Tracking **enemy ultimate** (or any enemy ability) cooldowns, whether manual or automatic.
- Reading game memory, injecting code, hooking the game process, or modifying game files.
- Sending input to the game: typing into chat, simulating keys or clicks, or macros.
- Automatically detecting enemy spell casts (screen capture, computer vision, audio, and so on).
- Using the League Client (LCU) API. v0.x uses only the Live Client Data API on `127.0.0.1:2999`.
- Ads, telemetry, or anything that phones home besides Riot's public Data Dragon CDN.

If you're unsure whether something is allowed, open a **Policy question** issue first. [docs/POLICY.md](docs/POLICY.md) explains the reasoning.

## Development setup

Requirements: macOS 15+ and a Swift 6 toolchain. The Xcode Command Line Tools are enough, and the full Xcode is optional.

```sh
swift build              # build everything
swift test               # run the test suite (Swift Testing)
swift format lint --strict --recursive Package.swift Sources Tests
swift format --in-place --recursive Package.swift Sources Tests   # auto-format
```

You don't need a running game for most work. The core is tested against recorded fixtures, and `summwatch-mock` replays them as a fake Live Client API (see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)).

### Project layout

| Path | What lives there |
|---|---|
| `Sources/SummwatchCore` | UI-agnostic core: API client, game session, cooldown math, Data Dragon. **Foundation only; never import AppKit or SwiftUI here.** |
| `Sources/SummwatchApp` | Menu bar app and overlay (AppKit + SwiftUI) |
| `Sources/SummwatchMock` | Fixture replay server and recorder |
| `Tests/` | Tests and recorded fixtures |
| `docs/` | Architecture, policy, and decision records (`docs/adr/`) |

## Workflow

1. Open or claim an issue before large changes so we can agree on the approach.
2. Branch from `main`: `feat/<short-name>`, `fix/<short-name>`, `docs/<short-name>`.
3. Keep PRs small and focused. Add or update tests for core logic.
4. Make sure `swift test` and the lint pass locally. CI runs both.
5. PRs are **squash-merged**, so the **PR title** becomes the commit message.

### Commit / PR title format

We use [Conventional Commits](https://www.conventionalcommits.org/). Release notes and version bumps are generated from them.

```
feat: add retro-adjust hotkey
fix(cooldowns): apply ARAM aura haste
docs: explain Gatekeeper "Open Anyway"
```

Types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`. Mark breaking changes with `!` (`feat!: …`).

### Fixtures and privacy

Recorded games contain other players' Riot IDs. **Only commit anonymized fixtures.** Raw recordings belong in `Tests/Fixtures/raw/`, which git ignores.

## Releases

Maintainers release via [release-please](https://github.com/googleapis/release-please). It opens a release PR that updates `CHANGELOG.md`, and merging that PR tags `vX.Y.Z`. Versions follow [SemVer](https://semver.org/). While in `0.x`, breaking changes bump the minor version.

## Code of conduct

This project follows the [Code of Conduct](CODE_OF_CONDUCT.md).
