# OFFGRID — Project Instructions

OFFGRID is an iOS music-discovery app for underground rap: one song per screen, no visible buttons while playing, taste learned invisibly from gestures and listening. Native SwiftUI client plus a planned backend. The founder owns the product vision; Claude acts as primary software engineer.

## Read first (in this order)
1. `docs/development/status.md` — what actually exists. The ONLY place a feature may be called done.
2. `docs/product/product-requirements.md` — what to build, and what V1 excludes.
3. `docs/architecture/decisions.md` and `docs/product/open-questions.md` — what is decided vs. open.
4. `docs/architecture/system-architecture.md`, `docs/development/roadmap.md`, `docs/development/testing-plan.md`.
Original source: `docs/OFFGRID DESIGN DOC.pdf` (v0.2 draft). If it conflicts with the founder's instructions, the founder wins — flag the conflict.

## Status labels (used in every doc)
- **CONFIRMED** — from the founder's spec or an explicit founder instruction.
- **PROPOSED** — suggested, not yet approved. Do not build as if settled.
- **OPEN** — unresolved. Ask the founder; do not guess.

## Non-negotiable product principles
- The song fills the screen. While playing: no visible buttons, no progress bar, no bottom bar.
- Interaction is invisible: taste comes from gestures and listening, never forms or rating widgets.
- No comments, no messaging, no friends, no sharing in V1.
- Three pages only: For You, Games, Profile.
- Underground by design: the catalog and recommender protect small artists.
- Every decision is tested against: does this put the song closer to the listener?

## Rules for working in this repo
- Never claim a feature is implemented or working unless it is built AND tested. Update `status.md` only with evidence (what was run, what passed).
- Do not delete, rename, move, or rewrite existing files without explicit approval. Do not create a new Xcode project.
- Do not invent technical capabilities or external permissions. SoundCloud is ruled out (founder, 2026-11-19). Audiomack is only a CANDIDATE provider: API access and usage permissions are NOT confirmed (Q-15). Do not write Audiomack integration code, and do not hardcode any provider into the core player or recommender, until the answer is recorded in `decisions.md`. Current scope: private, non-commercial, educational prototype on mock/demo tracks; private use does not by itself exempt us from a provider's terms. See `docs/architecture/feasibility-assessment.md` §2.7.
- Mock data stays separate from production data (see `docs/development/mock-data-policy.md`). Mock content must be unmistakably fake and never ship in a release build path by default.
- Keep it simple: no third-party dependency, framework, or service without a recorded reason in `decisions.md` and founder approval.
- Do not implement product features until the relevant roadmap phase is approved.
- Commit or push only when asked.

## Project facts
- Xcode project: `OFFGRID.xcodeproj` (uses the newer `project.xcproj` format with folder-based membership — add Swift files under `OFFGRID/` rather than hand-editing the project file). Bundle ID `com.offgrid.app`.
- Source today: template UI only. `OFFGRIDApp.swift` (renamed from `MyApp`, 1A.1) and template `ContentView.swift`. Tests live in `OFFGRIDTests/`, a folder-based Swift Testing target hosted by the app.
- Project file format: Xcode 27's JSON-style `project.xcproj`. Targets are `OFFGRID` (id `…0100000000`) and `OFFGRIDTests` (id `…0200000000`, `product-type` `bundle.unit-test`, `test-host-target` `OFFGRID`). The shared scheme is `OFFGRID.xcodeproj/xcshareddata/xcschemes/OFFGRID.xcscheme`. New Swift files go in the existing folders; editing the project file is only for target or setting changes, with approval.
- Toolchain: Xcode 27.2 (27B52). Apple Developer Program not enrolled: use the simulator; simulator builds sign locally and need no account.
- Build (verified 2026-11-19, `** BUILD SUCCEEDED **` on a clean build), run from the repo root:
  `xcodebuild -project OFFGRID.xcodeproj -scheme OFFGRID -destination 'platform=iOS Simulator,name=iPhone 17' build`
  If that simulator is missing, list the available ones with `xcrun simctl list devices available`.
- Test (verified 2026-11-19, `** TEST SUCCEEDED **`, Swift Testing, shared `OFFGRID` scheme), run from the repo root:
  `xcodebuild -project OFFGRID.xcodeproj -scheme OFFGRID -destination 'platform=iOS Simulator,name=iPhone 17' test`
  In Xcode: select the `OFFGRID` scheme and press ⌘U.
- Platform: iPhone only, portrait, minimum iOS 26.0 (ADR-013). Applied in the project file and guarded by `OFFGRIDTests/AppConfigurationTests.swift`.
- Device testing is deferred (ADR-020); use the Simulator.
- Docs live in `docs/`, split into `product/`, `architecture/`, `development/`.

## Conventions
- SwiftUI-first; Swift concurrency for async work; audio behind a protocol so the playback source can change.
- Test-first for logic (ranking, gesture state, scoring); see `docs/development/testing-plan.md`.
- Small, reviewable changes. Say what changed, what was verified, and what was not.
