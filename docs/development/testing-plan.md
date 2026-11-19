# OFFGRID — Testing Plan

Status: PROPOSED. No tests exist yet; there is no test target in the Xcode project. Founder decision (2026-11-19, ADR-014): the `OFFGRIDTests` unit-test target is created at the start of Phase 1A, not before, using Swift Testing, with the `OFFGRID` scheme shared so tests run from Xcode and from `xcodebuild test`. No placeholder tests; tests are added alongside the features they cover.

## 1. Principles
- A feature is "done" only when its tests pass AND it has been checked on a real device where the behavior depends on one (audio, haptics, gestures, lock screen). Evidence goes in `status.md`. Exception (founder, ADR-020): during Phase 1A, the iOS Simulator stands in for the device. Device-dependent behavior is recorded as "not verified on device" and re-checked on the founder's iPhone later.
- Test logic where it lives: put decisions (gesture states, ranking, scoring, game rules) in plain Swift/Python types that can be unit-tested without UI.
- Tests use mock data only through the mock layer; production data is never used in automated tests (`mock-data-policy.md`).
- Do not state test results that were not actually run.

## 2. iOS client
| Layer | What is tested | How |
|---|---|---|
| Unit | Gesture/screen state machine (playing ↔ paused, reveal, coach moment); Blind Ranking round rules (slot locking, disabled skip/back, likes not affecting ranking); interaction event batching; theme selection (system vs override); provider selection (release never mock). | Automated unit tests, run on every change. |
| Component/UI | Each state renders correctly in dark and light; no buttons visible in playing state; controls fade in on pause. | SwiftUI previews plus UI tests for the state transitions. |
| Gesture | Each approved gesture triggers exactly one action; similar gestures don't collide (design doc says to playtest). | UI tests where reliable; manual playtest on device otherwise. |
| Audio | Loop at snippet end; fade in/out; no auto-advance; prefetch makes transitions instant; background playback and lock-screen controls; interruptions (calls, headphones unplugged). | Manual on physical devices with a checklist; unit tests for the player's logic behind its protocol. |
| Accessibility | Resolution of Q-09 verified: VoiceOver, larger text, reduced motion, haptics off. | Manual checklist. |
| Performance | Memory and battery during long sessions; transition latency. | Instruments; numeric budgets TBD after first measurements. |

## 3. Backend (when it exists)
- Unit tests: underground filter gates (each gate, boundary values, config-driven thresholds), taste-vector updates, ranking formula, MMR and artist spacing, Blind Ranking scoring.
- Integration tests: API contract (each endpoint), database migrations, interaction ingestion, account deletion removes all user data.
- Test database is separate from any real one; fixtures live in `backend/fixtures/`.

## 4. Provider adapters, ingestion and ML (GATED on Q-15)
- Provider independence: tests drive the player, feed, and games through the protocols with mock providers only; a check (script or lint) fails if core code references a provider name, endpoint, or provider-specific field.
- Adapter contract tests: the same suite runs against every provider adapter using recorded or stubbed responses, never live calls in automated tests; includes expiring stream URLs, 403/408/422/503-style errors, and unplayable tracks.
- No real-provider test is written or run until Q-15 is answered and recorded.
- Snippet selection: hand-checked sample of tracks; fallback rules (about 30% start, under about 60 s plays from start) tested directly.
- Embedding model choice: benchmark on a labeled sample with results saved; nearest neighbors reviewed by someone who knows the scene.
- Pipeline: audio is not present on disk after a job finishes (automated check).

## 5. Recommendation quality
Offline: held-out likes ranked highly, diversity, coverage. Online (when users exist): like rate, listen-through, early-skip, session length, D7/D30 retention, and exposure distribution across artists. Any ranking change is compared against the current baseline before replacing it. Targets are set after a baseline exists; none are invented here.

## 6. Mock-versus-production checks
Automated: release configuration cannot resolve the mock provider; no `mock_` IDs in production database seeds. Manual: a release-configuration build is run once per milestone to confirm no mock content appears.

## 7. Quality gates
Before a milestone is marked complete: automated tests pass; manual device checks done and recorded; no known crash or data-loss bug open; dark and light themes checked; `status.md` updated with the date, what was run, and what was not covered.
