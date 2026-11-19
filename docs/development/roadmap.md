# OFFGRID — Development Roadmap

Phases follow design doc §11, with an added foundation step. Week ranges are the doc's indicative estimates, not commitments. A phase starts only when the founder approves it. A milestone is complete only when every completion criterion is met AND recorded with evidence in `status.md`, which is the only place progress is tracked.

## Phase 0 — Foundations and validation (doc weeks 1–2)
Goal: settle what blocks everything else, and make the repo safe to work in.

| Milestone | Completion criteria |
|---|---|
| 0.1 Repo hygiene | `.gitignore` added; user-specific Xcode files untracked; `docs/` and these documents committed; simulator build command verified once and recorded in `CLAUDE.md`. (The test target and test command moved to the start of 1A by founder decision, 2026-11-19; see ADR-014.) |
| 0.2 Decisions | Q-06, Q-07, Q-14 answered and logged in `decisions.md`; Q-08 and Q-13 explicitly deferred (to 1B and 1C) and the deferral logged. |
| 0.3 Audiomack API access and permissions | Founder has contacted Audiomack (done; no reply yet). Complete when a written reply answers each sub-question of Q-15 (search/aggregation, custom player, 20–30 s excerpts, background/lock-screen, artwork/metadata, credentials, licensing/partnership, ML analysis) and the answer, sender, and date are recorded in a new ADR. A founder go/no-go follows. If refused or silent after a period the founder sets, run the fallback: Audius spike or artist-licensed hosted snippets. Nothing is assumed granted while waiting. |
| 0.4 Seed catalog and embedding benchmark | Runs only if 0.3 permits. A seed catalog of roughly 5–10k tracks pulled within the granted terms; 2–3 embedding models compared on a labeled sample (about 500–1,000 tracks); the chosen model and the evidence recorded. |

Exit: 0.1–0.2 done. 0.3 may remain pending without blocking Phases 1A, 1B, or 2; it blocks only real music integration. 0.4 is waived for the private prototype (analysis exploratory only) unless 0.3 explicitly permits it.

## Phase 1 — Core listening (doc weeks 3–8)
Split into sub-milestones so the client can progress without waiting on rights. Frontend work (1A, 1B, Phase 2 on mock data) does not depend on the Audiomack decision.

| Milestone | Completion criteria |
|---|---|
| 1A iOS shell on mock data (independent of the provider decision) | At the start: `OFFGRIDTests` unit-test target created using Swift Testing, with the `OFFGRID` scheme shared so tests run from Xcode and the command line, and the test command verified and recorded in `CLAUDE.md` (ADR-014); deployment target set to iOS 26.0 and device family to iPhone only (ADR-013). Then: `MyApp` renamed to `OFFGRIDApp` with all references updated (approved, ADR-017); dark/light themes; three-page shell; For You playing and paused states; approved gesture set (ADR-015) driven by a unit-tested state machine; VoiceOver support with accessible alternatives for every gesture-driven action (ADR-016); mock provider and placeholder audio fully isolated per the mock policy; hidden status bar and background-audio configuration; meaningful tests added alongside each feature; manual test on a physical device recorded. |
| 1B Backend skeleton | Language chosen at the start of 1B (Q-08, deferred here by founder; Claude recommends an option then); API with health check, feed, and interaction endpoints against Postgres with migrations; contract documented; automated tests pass; no real provider data required. |
| 1C Real music integration (provider adapter), ingestion, snippets | GATED on milestone 0.3 and Q-15. Seed catalog curation (Q-13) is decided at the start of 1C. Starts only after a recorded provider answer; implemented as one adapter behind the provider-neutral protocols; embeddings only if separately permitted. Pipeline runs end to end on a small real sample; audio is discarded after analysis; snippet candidates and embeddings stored; underground filter thresholds read from config. |
| 1D Cold-start ranking and taste | Hand-weighted ranker, taste clusters with online updates, negative vectors, diversity and artist spacing, exploration share; unit tests with fixed fixtures; manual review of recommendations by someone who knows the scene. |
| 1E Integration | App uses `RemoteTrackProvider` against the backend; release configuration cannot select the mock provider; a single listening session works end to end with logged interactions. |

Exit: a tester can open the app and listen through a feed using all approved gestures, with interactions affecting later recommendations.

## Phase 2 — Games and Profile (doc weeks 9–12)
| Milestone | Completion criteria |
|---|---|
| 2A Blind Ranking solo | Round state machine unit-tested (locking, disabled skip/back, likes not affecting ranking); round endpoint and placement endpoint; result screen; Q-02 and Q-03 resolved first. |
| 2B Daily challenge | Only if Q-12 puts it in V1: same five songs for all players per day. |
| 2C Profile | Display name, liked songs, game history, theme setting and account; account deletion path. Taste summary only if approved. |

## Phase 3 — Quality (doc weeks 13–18)
Learned ranker replacing the hand formula; snippet bandits; collaborative embeddings; optional beat/vocal split. Each item must beat the current baseline on the offline and online measures in the testing plan before it replaces it. Accessibility (ADR-016) starts in 1A; any remaining Q-09 work (Switch Control, reduced motion, larger text) is completed here at the latest.

## Release readiness (PROPOSED, before any external testers)
Privacy note and takedown/opt-out process in place; accessibility pass; crash-free and performance review; App Store requirements checked against the current rules at that time (not assumed here); bundle ID and signing settled (Q-14).

## Phase 4 — Growth (not planned)
Android, artist-facing tools, new games, and social features only if the founder decides.

## Standing rules for every phase
Update `status.md` with evidence; keep mock and production separated; record decisions in `decisions.md`; resolve the relevant open questions before building the affected feature.
