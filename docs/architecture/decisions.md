# OFFGRID — Decision Record

Each entry: context, decision, reasoning, consequences. Status is **ACCEPTED** (founder-confirmed or follows from an explicit founder instruction), **PROPOSED** (awaiting approval), or **OPEN**. Add new entries at the end; do not rewrite history — supersede instead. (ADR-011 and ADR-012 sit next to ADR-008 because they supersede it.)

## ADR-001 — Native iOS app in SwiftUI · ACCEPTED
The founder's scope is an iOS app and the project already exists as a SwiftUI Xcode project. The design doc rates native SwiftUI best for Liquid Glass, gesture handling, and background audio. Consequence: Android is out of V1.

## ADR-002 — Keep the existing Xcode project and repo layout · ACCEPTED
Founder instruction: do not create a new Xcode project, and do not delete, rename, or move existing files without approval. New code is added under `OFFGRID/`; the project appears to use folder-based membership, so files are picked up without editing the project file. Consequence: renames such as `MyApp` → `OFFGRIDApp` and any move into `ios/` need explicit approval.

## ADR-003 — Documentation status labels and honesty rule · ACCEPTED
Founder instruction: distinguish confirmed requirements, proposals, and unresolved decisions; never claim a feature is implemented unless implemented and tested. Decision: use CONFIRMED / PROPOSED / OPEN everywhere, and make `docs/development/status.md` the only place that records completion, with evidence.

## ADR-004 — Playback and track data behind protocols; mock separated from production · ACCEPTED (rule) / PROPOSED (shape)
Founder instruction: keep mock data separate from production data. Decision: `TrackProvider` and `AudioPlayer` protocols; mock implementations only in `Mocks/`; explicit provider selection; `mock_` ID prefix. Reasoning: no real provider's rights are confirmed (Q-15), so the app must be buildable and testable without one. Consequence: UI work can proceed in Phase 1A without a backend.

## ADR-005 — Backend in Python with FastAPI · PROPOSED
Context: the ingestion, embedding, and ranking work depends on Python-native audio/ML libraries (the design doc names MERT, LAION-CLAP, Essentia, LightGBM). Decision: one language for API, workers, and ML, so the pipeline and API share code and types, with an OpenAPI contract for the client. Alternative: TypeScript/Node (also allowed by the doc); rejected for now because ML tooling would then live in a second language. Needs founder approval (Q-08). The doc is neutral between the two.

## ADR-006 — Postgres with pgvector for users, tracks, and embeddings · PROPOSED
From design doc §6.4/§8.2: simple and cheap for hundreds of thousands to low millions of tracks; move to a dedicated vector store only if scale demands. Consequence: one datastore to run in Phase 1B.

## ADR-007 — Defer Redis, learned ranker, bandits, and collaborative signals · PROPOSED
Avoiding unnecessary complexity. Phase 1 ships a hand-weighted cold-start ranker (the doc's own cold-start design). Learned ranking, snippet bandits, and collaborative embeddings wait for Phase 3 and for enough logged data. Redis is added only when a measured need exists.

## ADR-008 — SoundCloud: verify rights before depending on them · SUPERSEDED by ADR-011
Context: playback and analysis rights are unverified, and API access for new apps may be restricted (design doc §3.2). Plan A: official API with transient audio analysis. Plan B: written permission or partnership. Plan C: artist opt-in plus metadata/collaborative signals only. Decision pending the answer to Q-05. Until then no pipeline or playback code assumes any plan. Research update 2026-11-19: SoundCloud's published API terms appear to forbid downloading audio and using API content as AI/ML input, and restrict aggregated streaming and commercial use, so Plan A is not available without written permission; see `feasibility-assessment.md` §2. Recommended direction (PROPOSED, needs founder decision): artist-licensed catalog as the foundation, with Audius and SoundCloud as permission-gated options. The answer, who gave it, and the date are recorded here when received.

## ADR-011 — SoundCloud will not be used · ACCEPTED
Founder decision (2026-11-19): SoundCloud is out. Reasoning is in ADR-008 and `feasibility-assessment.md` §2 (published terms appear to bar audio download, AI/ML use, and aggregated streaming). Consequence: all SoundCloud-specific assumptions are removed from requirements and architecture; Q-05 is closed.

## ADR-012 — Audiomack as primary provider candidate; provider-independent core · OPEN (candidate) / PROPOSED (architecture rule)
Context: founder contacted Audiomack about API access and permissions on or before 2026-11-19; NO response yet. Nothing in this repo may state or imply that Audiomack has approved anything. Documented API capabilities (read 2026-11-19 from Audiomack's own API page, not terms; see assessment §2.7): search, song/album metadata, trending/recent by genre including rap, a preview-audio endpoint, and a playback endpoint returning a short-lived stream URL; OAuth 1.0a; the page states no rate limits, usage terms, or commercial/caching rules. Audiomack's general Terms of Service (read via summary) contain no API terms, prohibit automated retrieval other than by search engines and framing/modifying the Service, allow termination at its discretion, and are silent on aggregation, caching, third-party players, commercial use, and ML. Silence is not permission. Permissions: all unconfirmed, tracked in Q-15; the questions to send are in assessment §2.7.
Decision (PROPOSED): (1) Audiomack is the leading candidate only; real integration code waits for a recorded answer to Q-15. (2) The core player, feed, games, and recommender depend only on provider-neutral protocols (`TrackProvider`, `AudioPlayer`/playback source); any Audiomack specifics (endpoints, auth, URL expiry, field names) live inside one adapter. (3) Private, non-commercial, educational prototype scope: this does not exempt us from a provider's terms. (4) Audio analysis and embeddings are exploratory, not planned for the prototype. (5) Fallbacks: Audius, artist-licensed hosted snippets.
Consequences: frontend and mock-based work proceed independently; switching provider means writing one adapter, not rewriting the app. Record the Audiomack reply (who, when, exact scope) here when received, as a new superseding entry.

## ADR-009 — No third-party Swift dependencies by default · PROPOSED
No packages exist today. Add one only with a recorded reason here and founder approval. Reasoning: fewer moving parts and a smaller review surface.

## ADR-010 — Audio is never retained · PROPOSED
Only embeddings, metadata, and derived features are stored; audio is fetched transiently for analysis and discarded. From the doc's data-minimization stance; also keeps legal exposure smaller. Subject to Q-05.

## ADR-013 — Minimum iOS 26.0, iPhone only · ACCEPTED
Founder decision (2026-11-19), answering Q-06 and Q-07. The founder chose iOS 26.0 provided it supports the required features. Verification (Claude, 2026-11-19, against the iPhoneSimulator 27.2 SDK in Xcode 27.2): the SwiftUI interfaces mark `glassEffect`, `Glass`, `GlassEffectContainer`, and `GlassButtonStyle` as `@available(iOS 26.0, …)`. The other APIs the 1A shell expects need less: `sensoryFeedback` (iOS 17), `accessibilityAction(named:)` (iOS 13), `persistentSystemOverlays` (iOS 16), and `MPRemoteCommandCenter` (iOS 7.1). So iOS 26.0 supports Liquid Glass and the planned shell. Consequences: the project currently says iOS 27.2 and iPhone + iPad; the settings change (`IPHONEOS_DEPLOYMENT_TARGET` = 26.0, `TARGETED_DEVICE_FAMILY` = 1) is applied at the start of Phase 1A and verified by a build. Only the iOS 27.2 simulator runtime is installed today, so running on iOS 26 itself would need an iOS 26 runtime download; until then, availability is checked by the compiler against the 26.0 target. Any newer API used later needs an `#available` check or a raised target.

## ADR-014 — Unit tests use Swift Testing; test target created at the start of Phase 1A · ACCEPTED
Founder decision (2026-11-19). No placeholder test target in Phase 0. At the start of 1A: add an `OFFGRIDTests` unit-test target using Swift Testing, share the `OFFGRID` scheme so tests run from Xcode and the command line, verify the test command, and record it in `CLAUDE.md`. Tests are written alongside the features they cover. Consequence: milestone 0.1 requires only a verified build command; the test command became a 1A start criterion (`roadmap.md`).

## ADR-015 — Approved gesture set · ACCEPTED
Founder decision (2026-11-19), answering Q-01: double tap = like; single tap = pause/resume; swipe up = next song; swipe left = not interested (explicit negative signal, then next song). Long press (full-song link) is optional: build it only if it doesn't collide with the others. Not covered by the answer, still OPEN: swipe down for previous song and the first-run coach moment (GS-06). Gestures are interpreted by a pure, unit-tested state machine separate from views.

## ADR-016 — Accessibility: VoiceOver and gesture alternatives · ACCEPTED (rule) / PROPOSED (mechanism)
Founder decision (2026-11-19), answering Q-09 in direction: support VoiceOver, and give every essential action an accessible alternative so nothing essential depends on gestures alone. PROPOSED mechanism, to be confirmed during 1A: VoiceOver custom actions on the song surface (no visible buttons while playing, so the core principle holds), plus the paused-state glass controls as a visible alternative. Switch Control, reduced motion, and larger text are still OPEN under Q-09.

## ADR-017 — Rename `MyApp` to `OFFGRIDApp` · ACCEPTED
Founder approval (2026-11-19), with the condition that all references are updated safely. Done in Phase 1A: rename the file and type, update every reference, and verify with a clean build. This applies the rename that ADR-002 required approval for.

## ADR-018 — Bundle ID and display name · ACCEPTED
Founder decision (2026-11-19), answering Q-14: keep bundle ID `com.offgrid.app` and display name "Offgrid".

## ADR-019 — Deferred decisions: backend language and seed curation · ACCEPTED (deferral)
Founder decision (2026-11-19). Q-08 (backend language) is decided at the start of Phase 1B; Claude recommends an option then, and ADR-005 stays PROPOSED until that point. Q-13 (who curates the seed catalog) is decided at the start of Phase 1C, because the real provider is undecided. Neither blocks Phase 1A.

## ADR-020 — Swipe down, gesture coach, and simulator-only testing for now · ACCEPTED
Founder decisions (2026-11-19, when approving Phase 1A). (1) Swipe down = previous song is approved, alongside ADR-015, which completes Q-01. (2) A first-run gesture coach is approved: minimal and consistent with OFFGRID's design, shown once. (3) Physical-device testing is deferred: development and verification use the iOS Simulator, with no Apple Developer Program enrollment required. On-device checks (audio routing, haptics, lock screen, gesture feel) are re-checked on the founder's iPhone later. Consequence: 1A's "manual test on a physical device" criterion becomes "manual test in the Simulator", with the device check carried as a deferred item in `status.md`. Anything that only a device can confirm (for example haptics, which the Simulator does not produce) is recorded as "not verified on device".

## ADR-021 — Foundation interfaces and Debug-only mocks · ACCEPTED (founder-approved plan, 2026-11-19)
This fixes the shape that ADR-004 left PROPOSED.
- `TrackProvider` has two calls: `nextTracks(count:)` returns track details for an infinite stream, and `playbackSource(for:)` resolves audio just before playback. Resolving audio separately means a provider with short-lived audio links needs no special handling in core code.
- `Track` is provider-neutral: an opaque `TrackID`, title, artist, a `Snippet` validated to 20–30 s (including when decoded), and optional artwork and source-page URLs.
- `AudioPlayer` is a `@MainActor` protocol (load, play, pause, stop, state). Its implementation is in 1A.4.
- `App/AppEnvironment.swift` is the single selection point (mock-data-policy rule 4). Debug selects `MockTrackProvider`. Release selects `UnconfiguredTrackProvider`, which serves nothing, until a backend provider exists in 1E.
- Every file in `Mocks/` is wrapped in `#if DEBUG`, so mock types do not exist in Release builds.
- Placeholder audio is a plain sine tone per mock track, generated at runtime into Caches as WAV. No audio files are in the repo. It's temporary test audio, per the founder: kept simple.
- Enforcement is a source-scanning test (`MockIsolationTests`) that ignores comments and strings. Per founder direction, it checks only that production code outside `Mocks/` never references mock types, with `AppEnvironment` excepted inside `#if DEBUG`. It does not check provider names in text.
