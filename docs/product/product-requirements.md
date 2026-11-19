# OFFGRID — Product Requirements

Source: founder spec as captured in `docs/OFFGRID DESIGN DOC.pdf` (v0.2). Last reviewed: 2026-11-19.

## How statuses were assigned
The design doc states that items marked "(proposal)" are suggestions where the spec was blank. This document therefore treats **product and UX content that the doc does not mark as a proposal as CONFIRMED**, and treats **technical design (recommender, pipelines, infrastructure) as PROPOSED** unless the founder says otherwise. If any item below is mislabeled, correct it here first; other docs follow this one.

Labels: **CONFIRMED** · **PROPOSED** · **OPEN** (see `open-questions.md`, IDs like Q-01).

## 1. Vision
A music discovery app for underground rappers so the audience reaching each artist is targeted and real. Listeners get songs matched to their taste; artists get heard by people who actually like their sound. (CONFIRMED)

Philosophy: the music is the centerpiece. Every decision is tested against "does this put the song closer to the listener, or does it get in the way?" (CONFIRMED)

## 2. Principles (all CONFIRMED)
1. The song fills the screen; no visible buttons while a song plays.
2. Interaction is invisible; taste is learned from gestures and listening behavior, not forms or rating widgets.
3. No comments, no text-based social features, no friends system in V1.
4. Three pages only: For You, Games, Profile.
5. Targeted, not massive: a deliberately underground catalog that the recommender protects.
6. Deeper than genre: recommendations come from how songs sound, not genre or artist tags.

## 3. V1 scope (CONFIRMED)
- iOS app with For You, Games, Profile; iPhone only, minimum iOS 26.0 (founder, 2026-11-19; ADR-013)
- Catalog of underground rap from a third-party music provider. SoundCloud is ruled out (CONFIRMED, founder). Audiomack is the current primary candidate, with access and permissions NOT confirmed (OPEN, Q-15). The provider is not fixed; the product does not depend on any one provider.
- 20–30 second snippet playback
- Gesture-based liking
- Audio-embedding recommendation system that learns from each user
- Blind Ranking game
- Dark and light themes

## 4. Explicit V1 exclusions (CONFIRMED)
- Comments, messaging, friends, sharing, or any other social feature (may be added later at the founder's decision)
- Full-length in-app playback (full songs link out to the source provider's page or app, where permitted)
- Artist dashboards and artist uploads
- Android (follows after iOS is proven)
- Sign-up quizzes or rating forms (principle 2)

Backlog only, not committed: other games (Guess the Artist's Size, Head to Head), collaborative embeddings, beat/vocal split embeddings, import of likes from a music service (provider-dependent).

## 5. Functional requirements

### 5.1 For You
| ID | Requirement | Status |
|---|---|---|
| FY-01 | Opens straight into a song on launch; no splash menu. | CONFIRMED |
| FY-02 | Playing state: artwork fills the screen; only title and artist visible; no buttons, progress bar, or bottom bar; status bar and home indicator hidden or dimmed. | CONFIRMED |
| FY-03 | Paused state: glass control layer fades in; bottom bar with the three pages appears; secondary actions (open at the source provider, view artist) appear. | CONFIRMED |
| FY-04 | Resuming playback fades controls out within about a second. | CONFIRMED |
| FY-05 | Background is the artwork, blurred and extended; text color adapts for legibility. | CONFIRMED |
| FY-06 | Infinite stream; nothing ever auto-advances. | CONFIRMED |

### 5.2 Gestures
| ID | Gesture | Behavior | Status |
|---|---|---|---|
| GS-01 | Double tap | Like; brief glass pulse and soft haptic, nothing remains on screen. | CONFIRMED |
| GS-02 | Single tap | Pause / resume (pausing reveals controls). | CONFIRMED (founder, 2026-11-19) |
| GS-03 | Swipe up / down | Swipe up = next song: CONFIRMED (founder, 2026-11-19). Swipe down = previous song: OPEN (not covered by the founder's Q-01 answer). | Mixed |
| GS-04 | Swipe left | "Not interested": explicit negative signal, then next song. | CONFIRMED (founder, 2026-11-19) |
| GS-05 | Long press | Hold to reveal the full-song link at the source provider; release to dismiss. | OPTIONAL (founder, 2026-11-19): build only if it doesn't collide with other gestures; first to drop. |
| GS-06 | First-run coach moment teaches gestures once with controls visible, then never again. | PROPOSED |
| GS-07 | Accessibility: VoiceOver is supported, and every essential action (like, pause/resume, next, not interested) also works without the gesture, for example through VoiceOver actions or the paused-state controls. No essential function depends on gestures alone. | CONFIRMED (founder, 2026-11-19); exact mechanism PROPOSED in 1A |

### 5.3 Playback
| ID | Requirement | Status |
|---|---|---|
| PB-01 | Snippets of 20–30 seconds with short fade in/out. | CONFIRMED |
| PB-02 | When a snippet ends it loops and waits for the user. | CONFIRMED |
| PB-03 | Next song prefetched so transitions are instant. | CONFIRMED |
| PB-04 | Background audio continues on screen lock, with lock-screen controls via the system media session. | CONFIRMED |
| PB-05 | Playback method: in-app, 20–30 s excerpts with custom start offset, looping, fades, background and lock-screen playback, through the chosen provider's sanctioned mechanism. | OPEN — provider and permissions unconfirmed (Q-15) |
| PB-06 | Snippet start chosen by analysis (hook detection); fallback ~30% into track, or from start if under ~60 s. | PROPOSED |

### 5.4 Games — Blind Ranking
| ID | Requirement | Status |
|---|---|---|
| BR-01 | Five songs played one at a time; player places each into slot 1–5 without knowing what comes next; placement is locked. | CONFIRMED |
| BR-02 | Round uses the same full-screen playing state as For You; snippet loops and waits. | CONFIRMED |
| BR-03 | Skipping, going back, and changing a placement are disabled during a round; double tap still likes a song and does not affect ranking. | CONFIRMED |
| BR-04 | A single tap pauses and fades in five glass slot buttons (1–5), showing thumbnails for filled slots. | OPEN (Q-03) |
| BR-05 | Title and artwork revealed only after placement (setting if too harsh). | PROPOSED (Q-02) |
| BR-06 | Result screen: five stacked glass rows, community match %, streak; no share card; swipe up for another round. | PROPOSED (details); no share card is CONFIRMED |
| BR-07 | Score framed as "taste match" vs. community consensus; no right/wrong. | PROPOSED |
| BR-08 | Daily challenge: same five songs for everyone. | PROPOSED (Q-12) |
| BR-09 | Placements feed the recommender (slot 1–2 positive, slot 5 mild negative). | PROPOSED |
| BR-10 | Games page follows For You's rules: one full-screen artwork-driven surface, game name, one glass start control; swipe between games once more than one exists. | CONFIRMED |

### 5.5 Profile
| ID | Requirement | Status |
|---|---|---|
| PR-01 | Display name. | CONFIRMED |
| PR-02 | Liked songs (tap to play snippet). | CONFIRMED |
| PR-03 | Blind Ranking history and stats. | CONFIRMED |
| PR-04 | Theme setting (system by default, manual override) and account. | CONFIRMED |
| PR-05 | Taste summary from embedding clusters ("sound neighborhoods"). | PROPOSED |
| PR-06 | Short note on what the model learns from. | PROPOSED |
| PR-07 | No comments anywhere. | CONFIRMED |

### 5.6 Themes and visual language (CONFIRMED)
Extremely minimalist: one song, one screen, no lists or card feeds. Dark and light themes following the system setting. Native iOS glass (Liquid Glass materials) in SwiftUI.

### 5.7 Catalog and recommendation (PROPOSED unless noted)
- Catalog source: SoundCloud is excluded (CONFIRMED). Audiomack is the current primary candidate (PROPOSED; access and permissions unconfirmed, Q-15). Alternatives if it fails: Audius, artist-licensed hosted snippets (see feasibility assessment §2.6). Seed → search/filter ingestion (PROPOSED); whether a provider allows bulk crawling or aggregation is itself an open permission question (Q-15).
- Audio analysis and embeddings: the design vision stays (CONFIRMED as long-term intent). For the private prototype it is exploratory only and NOT planned for implementation; it needs explicit provider permission (Q-15f). Until then the prototype uses metadata and behavior signals only.
- Underground gates: ≤ 25,000 followers; < 250,000 plays; rap tag allowlist; not major-label; real song 1:30–6:00; minimum traction; playable; deduplicated. Thresholds are tunable config values, not hard-coded (PROPOSED; Q-04).
- Underground score (0–100) feeds ranking and an exposure boost for small artists (PROPOSED).
- Audio embeddings from a pretrained model, chosen by benchmark; 3–5 taste vectors per user; negative "avoid" vectors; decay (PROPOSED).
- Cold start without a sign-up quiz: diverse seed set, fast narrowing (PROPOSED). That there is no quiz is CONFIRMED.
- Exploration share and diversity re-ranking (PROPOSED).

### 5.8 Accounts and privacy
- Sign in with Apple as primary auth (PROPOSED, Q-11).
- Link every track back to its source provider with attribution; honor takedowns; artist opt-out; store embeddings and events, not audio; account deletion removes all user data (PROPOSED; provider terms unverified).

## 6. Non-functional requirements (PROPOSED unless noted)
- Dark/light themes both fully supported (CONFIRMED).
- Transitions feel instant via prefetch (CONFIRMED); numeric latency targets TBD after prototyping.
- Accessibility: VoiceOver support and accessible alternatives to every essential gesture (CONFIRMED, GS-07, ADR-016). Switch Control, reduced motion, and larger text details remain OPEN (Q-09).
- Privacy: data minimization; no audio retained.

## 7. Success metrics (PROPOSED; targets TBD)
Discovery (likes per session, share of likes from artists under the cap), engagement (listen-through, early-skip, session length, D7/D30 retention), recommendation quality (held-out like recall, exposure distribution across artists), games (participation, daily completion, streaks), artist outcomes (unique listeners reached).

## 8. Dependencies and risks
- Music provider access and permissions are the gating risk: SoundCloud is ruled out; Audiomack is unconfirmed. See Q-15 and ADR-011/012.
- Gesture discoverability; thin underground catalog; cold start; filter bubble. Mitigations are in the design doc §12.
