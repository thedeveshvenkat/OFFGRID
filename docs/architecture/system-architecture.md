# OFFGRID — System Architecture (Proposed)

Everything here is **PROPOSED** unless marked CONFIRMED. It derives from design doc §6 and §8 and is a starting point, not a commitment. Nothing described below is implemented (see `docs/development/status.md`).

## 1. Guiding constraints
- CONFIRMED: native iOS app in SwiftUI; 20–30 s snippets; invisible gesture-driven UI; SoundCloud is not used.
- OPEN: the music provider. Audiomack is the current candidate; its API access and usage permissions are UNCONFIRMED (Q-15, ADR-012).
- Provider independence (PROPOSED rule): catalog, playback source, and any analysis each sit behind a provider-neutral interface, so changing provider (Audiomack, Audius, artist-licensed hosted snippets, other) means writing one adapter. Core player, feed, games, and recommender must not contain provider names, endpoints, ID formats, or URL-lifetime assumptions.
- Simplicity first: build the smallest component set that serves the current roadmap phase. Defer anything marked "later".

## 2. Overview

```
 iOS app (SwiftUI)
   Features: ForYou · Games · Profile
   Core: Audio · Networking · Models · Storage
   TrackProvider ──┬── MockTrackProvider   (dev/test only, fixtures)
                   └── RemoteTrackProvider (talks to the API)
        │ HTTPS (JSON)
        ▼
 Backend API ──── Postgres (+ pgvector)
        │
        └── Worker queue ── Ingestion · Analysis · Embedding jobs
                              (audio fetched transiently, never stored)
 Redis: later, only if session/feed state needs it
```

## 3. iOS client (CONFIRMED technology; structure PROPOSED)
Responsibilities: render the three pages, own all gesture handling, play snippets, report interaction events, cache the next 2–3 prefetched songs and artwork, apply themes.

Planned layout under `OFFGRID/`:
- `App/` — `AppEnvironment` (the single provider-selection point, ADR-021); root navigation and page switching later. The entry point `OFFGRIDApp.swift` (renamed from `MyApp`, ADR-017) currently sits at `OFFGRID/` root; moving it here needs approval.
- `DesignSystem/` — themes (dark/light), glass components, artwork-driven color and blur.
- `Core/Audio` — `AudioPlayer` protocol and implementation: looping snippets, fades, prefetch, audio session for background and lock-screen playback.
- `Core/Networking` — API client; `Core/Models` — track, interaction, game types; `Core/Storage` — local cache.
- `Core/Providers` — `TrackProvider` protocol, `UnconfiguredTrackProvider` (Release default until 1E), `RemoteTrackProvider` later (1E).
- `Features/ForYou` — playing/paused state machine and gesture recognizer layer.
- `Features/Games/BlindRanking` — round state machine and result screen.
- `Features/Profile`.
- `Mocks/` — mock provider, fake catalog, and runtime-generated placeholder tones; every file is inside `#if DEBUG` (ADR-021; see `docs/development/mock-data-policy.md`).

Key design points:
- Gesture handling and screen state (playing/paused/reveal) are a pure, testable state machine separate from views.
- Playback is behind a protocol so the provider's playback method can change without touching features. Provider facts that differ by provider (for example, Audiomack's documented stream URL lasts only about 10 seconds, so it must be requested just before playback) are handled inside that provider's adapter, never in the player or feed.
- The client does not talk to a music provider directly unless Q-15 resolves that way. Where provider credentials (e.g. OAuth consumer secret) live, and whether stream URLs are fetched by the client or the backend, are OPEN and depend on the provider's terms; secrets never ship in the app.

## 4. Backend (PROPOSED; language is OPEN, Q-08)
Single API service plus workers; start as one deployable and split only if needed.
- **API:** `GET /feed/next`, `POST /interactions` (batched), `GET /games/blind-ranking/round`, `POST /games/blind-ranking/placements`, `GET /profile`. Sketch only; the contract is written down before client integration (OpenAPI if FastAPI is chosen).
- **Responsibilities:** serve feed queues (~10 tracks, refilled), record interactions, update user taste vectors, serve game rounds and score them, serve profile data.
- **Auth:** Sign in with Apple (Q-11).

## 5. Data (PROPOSED; simplified from the doc)
Postgres with pgvector for: `users`, `tracks` (`provider` + `provider_track_id`, metadata, underground score, embedding, tempo/key, snippet candidates), `interactions` (like, skip, swipe_left, full_listen, replay, listen_ms), `user_taste_vectors`, `game_rounds`, `game_placements`. Only embeddings and metadata are stored; audio is never retained. Redis is deferred until a concrete need appears.

## 6. Ingestion and analysis pipeline (PROPOSED; GATED on Q-15)
Seed → crawl → filter (gates from the product doc) → fetch audio transiently → beat grid and snippet candidates → embedding → features → write → discard audio. If analysis is not permitted, fall back to metadata and behavior signals only (or artist-opt-in audio). For the private prototype, analysis and embeddings are exploratory only and not planned; the long-term embedding vision stays in section 7 and the product requirements. No pipeline code is written until the answer is recorded.

## 7. Recommendation (PROPOSED; phased)
Phase 1: cheap retrieval by nearest-neighbor over taste vectors, a hand-weighted cold-start ranker, diversity and artist spacing, an underground guard, and a small exploration share. Phase 3: learned ranker, snippet bandits, collaborative signals. Model choice (MERT, LAION-CLAP, Essentia Discogs-EffNet) is decided by benchmark, not assumed.

## 8. Mock versus production (CONFIRMED rule)
- Mock data lives only in `OFFGRID/Mocks/` and `backend/fixtures/`.
- The app chooses its `TrackProvider` at one explicit configuration point; the default for release builds is the remote provider.
- Mock IDs carry a `mock_` prefix, and no real provider IDs, artists, or artwork are used in fixtures.
- Fixtures are never loaded into a production database. Details: `docs/development/mock-data-policy.md`.

## 9. Privacy, legal, and ethics (PROPOSED)
Attribution and link-back on every track; takedown and artist opt-out handling; account deletion removing all user data; store embeddings and events only. Terms compliance depends on Q-15.

## 10. Repository layout (PROPOSED)
```
OFFGRID/                (repo root)
├── CLAUDE.md, README.md
├── docs/               product/ architecture/ development/
├── OFFGRID.xcodeproj/
├── OFFGRID/            app source (App, DesignSystem, Core, Features, Mocks)
├── OFFGRIDTests/       added with the first testable logic
├── backend/            api, workers, migrations, fixtures (created when Phase 1B starts)
└── ml/                 benchmarks and snippet-selection experiments (created when Phase 0/1C starts)
```
Directories that do not exist yet are created only when their phase begins.
