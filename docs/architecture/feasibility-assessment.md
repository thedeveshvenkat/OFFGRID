# OFFGRID — Technical Feasibility Assessment

Date: 2026-11-19 · Scope: research and planning only; no application code was written or changed.
This is an engineering assessment, not legal advice. Anything about licensing needs a qualified lawyer before launch.

> **Revision 2026-11-19 (later):** the founder confirmed SoundCloud will NOT be used and is waiting on Audiomack (no reply yet). §1, §2 and the provider-dependent parts of §3–§5, §7, §9, §11–§19 were re-assessed for Audiomack as the primary candidate; other sections (auth, Blind Ranking, deployment, most UI) were not affected and were not redone. Audiomack has not approved anything. Decisions: ADR-011/012; open permissions: Q-15.

## 0. How to read this document

Evidence labels used throughout:

- **[V]** Verified: read in an official source (Audiomack, SoundCloud, Apple, pgvector, model cards) on 2026-11-19. URLs are in section 18.
- **[R]** Reported: stated by a third party (blogs, forums, aggregators), not confirmed officially.
- **[A]** Assumption or engineering judgment. Not verified here.
- **[U]** Unverified: could not be confirmed; must be checked before relying on it.

Caveat on provider terms: I read the Audiomack Terms of Service and API page through a page-summarizing fetch tool, not as raw text, so "the page says nothing about X" means the summary found nothing, not proof that the full text is silent. You (and later a lawyer) must read the full Terms of Service yourself before committing money or months. The SoundCloud conclusions (now historical) had the same limitation.

---

## 1. Deliverable 1 — Executive feasibility verdict (revised for Audiomack)

**Overall rating: the product is feasible; Audiomack as the catalog is technically promising but unproven, because nothing about permission is confirmed.**

What changed from the first assessment: SoundCloud's published terms contained explicit bans on AI/ML use, downloading and aggregated streaming, so it was close to a "no". Audiomack's published terms contain **no such explicit bans, but also no API terms at all**. That is better than a "no" and worse than a "yes": silence is not permission, Audiomack can terminate access at its discretion, and the API page does not even say how to get credentials. The decision is now a question of a written answer, not of reading a clause.

| Category | What falls in it |
|---|---|
| **Technically feasible (no third party needed)** | Immersive SwiftUI UI; gestures; themes; mock-data development of everything user-facing; background audio and lock-screen controls for any `AVPlayer` source; backend, Postgres/pgvector, Sign in with Apple, account deletion; Blind Ranking; a no-ML first recommender driven by listener behavior. |
| **Technically documented, permission unconfirmed (Audiomack)** | Search and genre/trending/recent lists; track and artist metadata and artwork; a preview-audio endpoint; a playback endpoint that returns a short-lived stream URL. All documented on Audiomack's own API page [V], none confirmed usable by OFFGRID. |
| **Feasible with significant limitations** | Playback of 20–30 s excerpts from Audiomack: the stream URL is valid for only about 10 seconds, which conflicts with "prefetch the next song" unless the preview endpoint or a short buffered read is permitted; custom start offsets, looping and fades depend on how the stream behaves [U]. Underground filtering depends on follower/play fields the API may not expose [U]; the catalog also includes the three major labels and 400+ independents [R], so a filter is essential. |
| **Dependent on Audiomack permission** | Everything above that touches their content: searching/aggregating, playing in a custom player, excerpts with custom timing, artwork/metadata display, background playback, credentials, any licensing or partnership terms, and ML analysis/embeddings (asked; exploratory only, not planned). |
| **Not recommended for V1 / the prototype** | Bulk crawling or scraping (the Terms prohibit automated retrieval other than search engines [V]; use the official API only); any audio analysis or embeddings of Audiomack audio; storing audio or stream URLs; commercial or public release on Audiomack data without a written agreement; GBM ranker, bandits, Redis, daily challenge, multi-vector clusters, likes import. |

**Verdict in one sentence:** keep building the experience on mock data, treat Audiomack as a candidate whose answer you are waiting for, run a technical playback spike only after you hold credentials and a written answer, and keep Audius and artist-licensed snippets ready as the fallback so the app never depends on one provider.

---

## 2. Section B — Music catalog and provider (Audiomack)

### 2.1 SoundCloud: ruled out (record only)
Founder decision 2026-11-19 (ADR-011). Why it was set aside, in brief: its API Terms (read via fetch) appear to bar downloading or caching content, using content as AI/ML input or for fingerprints, and building an on-demand service that aggregates many uploaders; commercial use was narrow; access revocable at will; stream requests capped at 1,500 or 15,000 per day (the official pages disagree). Nothing in the rest of this document depends on SoundCloud.

### 2.2 Audiomack: what is verified about access
- Official API page (read 2026-11-19): base `https://api.audiomack.com/v1`; HTTPS required; JSON; **OAuth 1.0a** with a consumer key/secret. Access tokens last one year. The page does not explain how to obtain a consumer key. [V]
- Authenticated user actions (favorite, repost, playlist edits) use a three-step user-authorization flow; the page does not say that search, metadata, preview or play calls need user authorization, so read-only access may need only the app's consumer credentials [V that the page is silent; A on what that means].
- Audiomack's Terms of Service page points API questions to its developer documentation or support@audiomack.com, and the creators contact page has a "Business inquiries" link; no API or developer option was visible on that page [V via fetch].
- Third-party sites disagree with the official page (some say OAuth 2.0, free access for approved developers, partnership tiers for commercial use) [R]. They are low reliability and are not evidence of a program; treat the official page as the authority and ask Audiomack directly.
- Scale and fit [R, trade press]: about 50 million monthly active users reported in January 2026, a strong hip-hop and Afrobeats focus, and a catalog that includes all three major labels plus 400+ independents. That is a big, relevant audience, but not an "underground only" catalog, so the underground filter in the design doc becomes a core feature rather than a convenience.

### 2.3 Documented API capabilities [V: Audiomack API page, 2026-11-19]
| Need | Documented endpoint | What is not known [U] |
|---|---|---|
| Search | `GET /search` (query, songs/albums/artists, sort relevance/recent/popular, genre such as rap, verified flag, paging); `GET /search_autosuggest` | Response fields; deep paging limits; whether it returns artist follower or play counts |
| Metadata | `GET /v1/music/:id` or by artist/slug; recent and trending lists, including by genre (rap); hourly metrics | Whether follower count, total plays, release date, tags, duration, label/major status, artwork URLs are returned |
| Preview audio | `GET /v1/music/preview/:id` returns audio (mp4 or mpeg); errors for unreleased/private/album, still generating, bad ID | Preview length and position; whether it suits 20–30 s excerpts; whether previews may be used in a custom player |
| Playback | `POST /v1/music/:id/play` returns the stream source URL; `session` parameter used for play statistics; `hq` option; `streaming_url` is an MP3 path valid for about 10 seconds; a call exists to report a track unplayable | Whether seeking/range requests work; start offsets; whether playing excerpts counts; permission to use outside Audiomack's apps |
| Play statistics | A stats token request, to be made when a user views a track | Whether it is required for compliance |
| Rate limits | Not stated | Everything (a third-party source says 429 with Retry-After [R]) |
| Offline / caching | Not stated | Whether any caching, including the buffer for prefetch, is allowed |

### 2.4 What the Terms of Service say, versus what OFFGRID needs
This is Audiomack's general Terms of Service, not API terms; no API or developer terms were found. Read via fetch [V that the summary says this; read the full text yourself].

| OFFGRID needs | What the Terms say | Reading |
|---|---|---|
| Search/aggregate public tracks | Using spiders, readers, or other devices to retrieve or index the Service is prohibited except for major public search engines. | **Scraping is out; the official API is the only route.** Whether the API grants aggregation rights is unaddressed. |
| Custom player (frame/reformat) | Reformatting or framing parts of the Service, and altering or modifying the Service, is prohibited. | **Risk** for a custom front end if it counts as modifying the Service; not clear for API use. Needs written clarification. |
| Excerpts with custom timing | Not addressed. | **Unconfirmed.** |
| Background playback / lock screen | Not addressed (a technical capability of iOS, not of the provider). | Technically feasible; permission unconfirmed. |
| Artwork and metadata display | Not addressed beyond attribution rules (do not falsify or remove author attribution). | Likely requires attribution and link-out [A]; confirm. |
| Caching / downloading by third parties | Not addressed; Audiomack says it is not a data warehouse and offers offline play in its own apps. | **Treat as not permitted** (do not store audio or stream URLs). |
| ML/AI analysis, embeddings | Not mentioned. | **Unconfirmed; asked.** Exploratory only; not planned for the prototype. Silence is not a license. |
| Commercial use | Not addressed (users may not post ads/promotions). | **Unconfirmed**; prototype stays private and non-commercial. |
| Continuity | Audiomack may change, suspend or end any service or terminate access at its discretion, without notice. | **Permanent platform risk** even with permission. |
| Takedowns/artist rights | Responds to DMCA notices; may remove content. | Handle unavailable tracks gracefully; honor removals. |

Private, non-commercial use is not assumed to be exempt from any of this.

### 2.5 Technical consequences for OFFGRID (all inside one provider adapter)
1. **The 10-second stream URL** means the URL must be requested immediately before playback. "Instant transitions by prefetching the next song" would have to prefetch audio bytes, which may count as caching [U], or rely on the preview endpoint if its length and terms fit. Needs a spike after permission.
2. **Who calls the API.** OAuth 1.0a signing needs the consumer secret, and secrets must not ship in the app. So the backend either signs requests and returns a short-lived URL to the app, or relays audio (relaying/proxying audio is a bigger terms question). A backend therefore comes before real music, as in the original roadmap analysis. Which design is allowed is OPEN.
3. **Start offsets and loops.** An MP3 stream can be sought if the server supports range requests [U]. If it does not, snippets can only start at 0, which breaks the "hook" idea and the 30% fallback. A one-day spike on a real iPhone, after permission, answers this.
4. **Underground filter.** Needs follower and play counts per artist/track; unknown whether the API exposes them [U]. Fallback: filter by curated artist seed lists, plus whatever fields exist.
5. **Rate limits** are unpublished; design for 429 handling, caching of metadata only if permitted, and a small curated catalog rather than crawling.
6. **Unplayable or removed tracks** need a graceful skip path (the API even provides a way to report unplayable tracks).
7. **Data storage:** store only IDs and the minimum metadata the terms allow until clarified; never store audio or stream URLs.

### 2.6 Alternatives (fallbacks)
| Option | Technically | Rights/terms | Verdict now |
|---|---|---|---|
| **Audiomack (primary candidate)** | Documented search, metadata, preview, short-lived stream URL [V] | Unconfirmed; no API terms found [V]; ML silent | **Wait for a written answer; spike only after.** |
| **Artist opt-in submissions (OFFGRID-hosted snippets)** | Full control: you host 20–30 s clips, any analysis, choose starts. | Artist grants OFFGRID a license (lawyer review). | **Strongest rights position; best fallback and the only route that cleanly allows embeddings.** |
| **Audius** | REST API to query, stream and search; free plan 10 req/s and 500k requests/month [V]. | Open Music License grants streaming rights; silent on analysis [V]. | **Spike for underground-rap depth if Audiomack stalls.** |
| **SoundCloud** | n/a | Ruled out (§2.1). | **Excluded.** |
| **Apple Music / MusicKit** | 30-second previews and metadata in the catalog API [V]. | Permitted use in discovery apps unclear; asks for the same permission questions. | Possible later; not a fit as a custom no-UI player. |
| **Spotify Web API** | New apps lost recommendations, audio features and preview URLs on 2024-11-27 [V]. | Playback needs Spotify's own SDK/app. | Not viable. |
| **Bandcamp / YouTube / licensed B2B clips** | No public catalog API / audio isolation prohibited / wrong catalog. | See first assessment. | Not viable / not a fit. |

### 2.7 Questions to send Audiomack (concrete, so the reply is usable)
Send in writing (support@audiomack.com is the address the Terms page gives for API questions [V via fetch]; the creators "Business inquiries" form is another route). Ask for answers in writing and note the sender and date. Tracks Q-15 a–h.
1. How do I obtain API credentials for a private, non-commercial educational prototype, and what are the approval criteria and rate limits?
2. May the app search Audiomack and aggregate public tracks from many artists into a feed?
3. May it play tracks in its own player (not Audiomack's), and with custom playback behavior?
4. May it play 20–30 second excerpts with custom start points, looping and fades, and may it buffer the next track ahead of time (the stream URL lasts about 10 seconds)?
5. May playback continue in the background and on the lock screen?
6. May it display artwork, titles and artist names, and what attribution and link-out are required?
7. Are machine-learning audio analysis and embedding generation permitted, if the audio is processed and discarded? (Asked; exploratory only.)
8. Are any license, partnership or fee agreements required, and do the answers change for a public or commercial release?

**Decision rules (PROPOSED):** a written yes (even partial) is recorded as a new ADR and the adapter is built to exactly that scope; a written no, or no reply within a window the founder chooses, switches the plan to artist-licensed hosted snippets and an Audius spike; silence is never treated as yes.

---

## 3. Deliverable 2 — Feature-by-feature feasibility

Ratings: **High** (standard work), **Medium** (doable, needs care or a decision), **Low** (heavily constrained), **Blocked** (cannot proceed without a third-party decision).

| Feature | Feasibility | Complexity | External dependency | Main risk | Recommended approach |
|---|---|---|---|---|---|
| Immersive full-screen player UI (artwork, blur, adaptive text) | High | Medium | None | Polish effort, color/contrast edge cases | Build in SwiftUI against a `TrackProvider` protocol and mock data. |
| Gesture set (double tap, tap, swipes, long press) | High | Medium-High | None | Gesture conflicts (below §4.1); discoverability; accessibility | Gesture state machine, unit-tested; device playtests early. |
| Dark/light themes | High | Low | None | None significant | System-driven plus override. |
| Navigation For You / Games / Profile with hidden bar | High | Medium | None | Bar appearing on pause; state restoration | Single root view with explicit state, not default tab bar. |
| Background audio + lock-screen controls | High | Medium | Apple capabilities | Audio-session edge cases (interruptions, route changes) | `AVAudioSession` playback category, audio background mode, now-playing center (Apple docs [V]). Test on a real phone. |
| Playback of tracks from **own-hosted** snippets | High | Low-Medium | Hosting/CDN | None | HLS or short AAC files via `AVPlayer`. [A] |
| Playback of **Audiomack** tracks in the custom player | Medium (technical) / Unconfirmed (permission) | Medium-High | Audiomack written permission; credentials | 10-second stream URL vs prefetch; seek/loop behavior unknown; termination at their discretion; no published rate limits | Spike on a real iPhone only after permission; keep behind the provider adapter and `SnippetPlayer`. |
| 20–30 s snippets with loop + fade | High (own-hosted audio) / Medium (Audiomack stream or preview; seek, range and loop behavior [U]) | Medium | Provider | Precision and latency of seeks; loop gaps; may be start-from-zero only | Fixed start (design's 30% fallback) first. |
| Hook detection (beat grid, self-similarity, scoring) | Medium (own audio) / Not planned (Audiomack audio; ML permission asked, exploratory only) | High | Audio rights | Heavy to build, unproven value | Defer. Use fixed starts, then learn good starts from listener behavior (listen-through) instead of audio analysis. [A] |
| Prefetch next song, "instant" transitions | Medium | Medium | Provider | Memory, battery, HLS startup latency | Prefetch one item; measure. |
| Artwork loading/caching | High | Low | Provider URLs | Image caching rules per provider | System `URLCache`/small image cache. |
| Loading/error/unavailable states | High | Medium | Provider | Track becomes unavailable mid-session; offline | Design these states early; they are most of the "polish". |
| Sign in with Apple + accounts | High | Medium | Apple Developer Program ($99/yr) [R for capability gating] | Token revocation on deletion | Backend verifies Apple identity tokens; in-app deletion required (Apple 5.1.1(v) [V]). |
| Likes/skips/history persistence | High | Low-Medium | Backend | Event volume design | Append-only events table, batched upload. |
| Catalog search and seeding from Audiomack | Medium (technical) / Unconfirmed (permission) | Medium | Audiomack | Scraping prohibited (official API only); aggregation and caching unaddressed; rate limits unpublished; underground fields unknown | After permission: on-demand search plus a small curated seed through the API; store IDs and minimal metadata; no crawling. |
| Catalog ingestion from artist submissions | High | Medium | Legal agreement | Recruiting artists; rights paperwork | Simple submission page + license checkbox; manual review at first. |
| Underground filter | High | Low-Medium | Data fields | Metadata quality | With artist-submitted music, the filter becomes "who you admitted" — simpler. |
| Audio embeddings (own/licensed audio) | Medium-High | Medium | Model license | MERT weights and Essentia models are non-commercial [V]; quality on rap unproven [U] | Benchmark LAION-CLAP (Apache-2.0 checkpoints [V]) first; get a commercial license or choose differently if MERT/Essentia win. |
| pgvector similarity search | High | Low | Postgres host | None at V1 scale | 128–256 dims is well within limits (HNSW up to 2,000 dims [V]). Exact search is fine for thousands of tracks. [A] |
| Multi-vector taste clusters | Medium | Medium | Interaction data | Little data early; extra complexity | Start with one vector (liked minus disliked); add clusters when evidence shows one vector fails. |
| LightGBM ranker, bandits, collaborative filtering | Medium | High | Lots of data | No data at launch | Phase 3+, behind measured need. |
| Blind Ranking (solo) | High | Medium | Tracks + backend | Pacing, hidden-info UX | Mostly client logic; server stores results. |
| Daily challenge | High | Low-Medium | Backend | Time zones, one-per-day rules | Postpone past V1 core. |
| Community-consensus "taste match" | Low early | Medium | Many players | Meaningless with few players | Show personal stats first; add consensus after real volume. [A] |
| Account deletion with full data removal | High | Medium | Backend | Forgotten data stores/logs | Design deletion into schema from the start. |

---

## 4. Section A — iOS application and UI

### 4.1 What is harder than it looks
1. **Single tap vs double tap.** To act on a double tap, the single-tap action must wait for the double-tap window, so pause feels slightly delayed unless handled carefully. [A, standard UIKit/SwiftUI behavior]
2. **Swipe up = next vs the system home gesture.** With the home indicator hidden, iOS may require an extra swipe from the bottom edge to leave the app, but accidental edge swipes near the bottom still happen. [A] Test on device; consider starting gestures away from the bottom edge.
3. **Swipe left vs system back/edge gestures** and vs long press on the same surface — needs explicit gesture priority.
4. **Accessibility.** A button-free UI is hard for VoiceOver, Switch Control and Voice Control users. The paused state shows controls, which helps, but there must be accessibility actions for every gesture. This is also an App Review and legal-exposure question. [A] (Q-09)
5. **Seamless audio:** looping a snippet without a gap, fades, and prefetching the next song while keeping the audio session active in the background. [A]
6. **Hidden status bar / home indicator** behavior varies by device and mode. [A]
7. **Liquid Glass**: depends on your minimum iOS version and the exact APIs in your Xcode; verify against Apple's current docs before committing. [U]

### 4.2 Playback architecture
Put audio behind a protocol (`SnippetPlayer`) so the source (Audiomack stream or preview URL, own-hosted HLS, Audius) can change. Apple's media-playback guidance: use the `playback` audio-session category, enable the audio background mode, and register now-playing/remote commands for lock-screen control. [V] These are iOS capabilities that work for any `AVPlayer` source; whether Audiomack permits background or custom-player use is a separate, open permission (Q-15d). Because Audiomack's stream URL is documented as valid for only about 10 seconds [V], the adapter must fetch it just before playback and handle expiry; the player must not assume a long-lived URL.

### 4.3 Other
- Artwork: cache on disk; extract dominant color for adaptive text. Standard.
- Network failure: show a quiet, in-theme state; keep the current snippet looping; queue prefetch retries.
- Physical-iPhone testing is essential for audio, haptics and gestures; simulators are not a substitute. [R: Apple's Xcode documentation as quoted by a third-party guide]


---

## 5. Section C — Backend and infrastructure (Deliverable 3: recommended V1 architecture)

### 5.1 Is the proposed stack too complex?
Yes, for V1. The design lists API + Postgres/pgvector + Redis + worker queue + object storage + a GBM ranker + bandits. Most of that is justified only by scale or data that will not exist at launch.

| Component | Needed for V1? | Reasoning |
|---|---|---|
| Python + FastAPI | **Yes (recommended)** | The audio/ML work is Python-native; one language for API, ingestion and experiments. Alternative (Node) is fine for the API but forces a second language for ML. [A] |
| PostgreSQL | **Yes** | One datastore for users, tracks, events, games. |
| pgvector | **Yes, but small** | Store embeddings next to tracks. With a catalog in the thousands, exact nearest-neighbor search is fast enough; add an HNSW index only when needed. HNSW supports up to 2,000 dims for `vector` and 4,000 for `halfvec` [V], so 128–256 dims is no issue. |
| Redis | **No** | Session/feed state can live in Postgres or in the client at this scale. Add only when a measured need appears. |
| Background worker queue | **No at first** | Run ingestion/embedding as scripts or a single scheduled job on your machine or one small worker. A queue framework is for continuous high volume. |
| Object storage / CDN | **Yes if hosting artist snippets** | Short AAC clips are small: a 30 s clip at 128 kbps is about 0.5 MB, so 10,000 clips is ~5 GB. [A, simple arithmetic] |
| LightGBM ranker, bandits, collaborative | **No** | Phase 3, only after logged data shows the simple method failing. |
| GPU | **No** | A ~95M-parameter model (MERT-v1-95M size [V]) on a short clip runs on CPU; benchmark before buying anything. [A] |

### 5.2 Recommended V1 architecture
```
 iPhone app (SwiftUI)
   └─ TrackProvider ── RemoteTrackProvider ──HTTPS/JSON──▶  API (FastAPI, one service)
   └─ SnippetPlayer (AVPlayer, HLS/AAC)                         │
                                                                ├─ Postgres (+pgvector)
 Artist submission page (simple web form) ─────────────────────┤
                                                                └─ Object storage (snippets + artwork)
 Offline scripts on your Mac / one small worker:
   ingest → trim snippet → (optional) embed → write to Postgres/storage
```
- **Why one service:** easier to run, debug, and let an AI coding agent reason about; split later.
- **Music provider:** Audiomack as the candidate source, only after written permission, behind a single adapter; artist-submitted hosted snippets as the rights-clean fallback; Audius as a second fallback after a spike. The backend holds provider credentials and signs requests (OAuth 1.0a needs a secret that must not ship in the app); whether it may also relay audio is an open terms question.
- **Recommendation:** start without audio ML (§7), add embeddings once there is licensed audio and a benchmark. (See §7.)
- **Hosting:** a managed Postgres plus one small web service (see costs, §16). Managed Postgres with pgvector is offered by common providers; confirm extension support on your chosen host. [U]

### 5.3 App ↔ backend communication
HTTPS JSON REST with an OpenAPI contract generated from FastAPI. The client sends batched interaction events (every few seconds or on app background) and receives a queue of ~10 tracks with snippet offsets. Keep the client dumb: ranking and feed logic live on the server.

### 5.4 Authentication
See §6.

### 5.5 Storing interactions and metadata
- Interactions: append-only event log (`user_id`, `track_id`, type, listen_ms, snippet_start, timestamp). Derive aggregates later.
- Track metadata: store what you are licensed to store. For an artist-submitted catalog, that is everything you collected. For Audiomack, store IDs and the minimum metadata until written permission says more; its Terms do not address third-party caching [V via fetch], and the stream URL expires in about 10 seconds, so never store stream URLs or audio.

### 5.6 Protecting credentials and data
- Provider secrets (any API client secret) live **only on the server**, never in the app: an iOS binary can be inspected. Client Credentials tokens are server-held. [A]
- Environment variables per environment; secret manager from the host; no secrets in git (see `.gitignore` task in roadmap).
- Tokens: short-lived access tokens + refresh; verify Apple identity tokens server-side. [A]
- Use TLS everywhere; hash nothing you don't have; collect the minimum personal data (design §9).

### 5.7 Feed delivery
`GET /feed/next` returns ~10 tracks. V1 logic is a SQL query plus a small scoring function (§7), not a model-serving system.

---

## 6. Section D — Authentication and accounts

- **Sign in with Apple** is the right primary login. You get a stable per-app user ID and optional email/name. If you also offered another third-party login, Apple's guideline 4.8 would require an equivalent privacy-preserving option; offering only Sign in with Apple avoids that. [V/R]
- **In-app account deletion is mandatory** for any app that supports account creation (Guideline 5.1.1(v)), and apps using Sign in with Apple must revoke Apple tokens via the REST API on deletion. [V: Apple App Review Help and "Offering account deletion" page]
- Apple also says: if the app has no significant account-based features, allow use without a login. [V] OFFGRID's value (taste learning, likes, history) justifies an account, but a **device-bound anonymous start with sign-in later** would reduce friction. Your design says "no sign-up quiz"; Sign in with Apple is a single tap, so it fits. (Open Q-11.)
- **Paid developer membership needed early:** a free Personal Team has provisioning profiles that expire after 7 days, at most 3 registered test devices and 10 App IDs [V: Apple membership comparison], and reportedly cannot use some capabilities, including Sign in with Apple [R]; TestFlight and the App Store need the $99/year membership. [V for the 7-day/3-device limits; R for the capability list.]
- What to build: Apple-token verification endpoint, user table, session/refresh tokens, profile read/update, deletion that cascades through events, taste vectors, game data and logs, plus Apple token revocation.
- Services that could simplify: a managed auth provider (for example Supabase Auth) could handle sessions; confirm Apple support and that it fits your host choice before depending on it. [U]
- Privacy: privacy policy URL and App Store privacy labels are required for submission [V: App Review guideline 5.1.1 lists privacy policy requirements]. Keep the "what the model learns from" note in Profile.

---

## 7. Section E — Recommendation system

### 7.1 Is the proposed system realistic?
It is realistic **as a plan**, but built in the wrong order and on a provider foundation that is still unconfirmed. The first useful recommender needs far less than the design describes, and for the private prototype it should use metadata and listener behavior only.

| Question | Answer |
|---|---|
| Can MERT/CLAP/Essentia embeddings be useful for underground rap? | Plausible but **unproven**. MERT's paper claims strong results on 14 general music-understanding tasks [V: arXiv abstract], not on rap sub-style similarity; I found no published evidence for rap sound-alike quality. Benchmark on a labeled sample (design §6.2 already says this). [U] |
| Model licenses | MERT checkpoints: CC BY-NC 4.0, non-commercial [V]. Essentia models: CC BY-NC-SA (the models page) or BY-NC-ND (the licensing page; the two disagree); commercial use needs a proprietary license "upon request"; the Essentia library itself is AGPLv3 with a commercial option [V]. LAION-CLAP checkpoints on Hugging Face: Apache-2.0 [V]. For a commercial product, **start the benchmark with CLAP**, and treat MERT/Essentia as research-only unless you buy a license. |
| Compute | A short clip through a ~95M-parameter model is modest. A few thousand clips on a laptop CPU is plausible; benchmark before assuming. [A] |
| Embeddings without retaining copyrighted audio? | Technically yes (decode → embed → discard), but it needs the audio, and Audiomack's stream/preview use is unconfirmed. Audiomack's Terms do not mention ML [V via fetch]; that is silence, not permission. Asked; exploratory only, not planned for the prototype. With artist-licensed audio you decide the policy. |
| Data needed | Embeddings need only audio. Personalization needs **interactions**: likes, skips, listen-through. Expect to need hundreds of active users and tens of thousands of interactions before learned models beat simple ones. [A] |
| New user with no history | Serve a diverse seed set (design §6.8), narrow after 5–10 interactions. With a small catalog, diversity can be hand-curated or tag-based at first. |
| Are multiple taste vectors worth it initially? | **No.** One vector (average of liked, minus a fraction of disliked) plus diversity re-ranking is a strong baseline. Move to multiple vectors only if measurements show one vector blurs users with mixed taste. [A] |

### 7.2 Realistic progression
1. **Stage 0 — No ML (launch).** Filter to eligible tracks, remove already-seen, sort by a mix of freshness, a small-artist exposure boost, and tags/artist spacing; random exploration share. Collect events.
2. **Stage 1 — Behavior only.** Add a per-track quality score from like/skip/listen-through (smoothed) and "liked by people who liked X" once there are users. Learn good snippet start offsets from listen-through (a lightweight bandit) — this gets hook-like starts without audio analysis. [A]
3. **Stage 2 — Content embeddings (only with licensed audio).** One taste vector per user = mean(liked) − k·mean(disliked); candidates by nearest neighbor; MMR for diversity.
4. **Stage 3 — Richer personalization.** Multiple taste vectors, a learned ranker, collaborative embeddings — each introduced only after it beats the previous stage offline on held-out likes and online on like-rate/retention. [A]
**When ML is justified:** when the simple baseline's metrics plateau and you have enough logged impressions to train and evaluate; until then, more complexity mostly adds bugs.

---

## 8. Section F — Blind Ranking

- **Round generation:** five tracks chosen server-side; solo mode mixes the player's taste area with a few outside it (needs a recommender; at launch, a diverse random draw is fine).
- **Presentation:** same full-screen player state; five placement slots appear when paused. One-at-a-time with locked placements is simple client state; store the finished round on completion. (Q-03 raises the visible-slot-buttons tension with "no visible buttons".)
- **Hidden info:** hide title/artwork in the UI until placement. The server may still send the data; client-side hiding is fine since cheating has no stakes. [A]
- **Saving results:** one `game_rounds` row, five `game_placements` rows.
- **Daily challenge:** deterministic selection by date (a table of daily rounds); time zones and one-attempt rules are the only snags.
- **Comparing users:** consensus scoring needs many players per round; it is meaningless at launch. Ship "your ranking" and personal history first; add community match later.
- **As a recommender signal:** placement 1–2 as positives, 5 as a mild negative (design §6.3) is reasonable; cheap to add after the event pipeline exists.
- **Challenges:** backend needs a round generator and idempotent placement submission; frontend needs a careful state machine (can't skip/go back). Neither is hard. The real dependency is having enough good tracks.

---

## 9. Section G — Practical V1 data model

Tables (PostgreSQL). `id` fields are UUIDs unless noted.

| Table | Key columns | Notes |
|---|---|---|
| `users` | id, apple_sub (unique), display_name, theme, created_at, deleted_at | Cascade-delete target. |
| `artists` | id, name, links (json), opted_in_at, license_ref, removed_at | Records the permission you hold. Supports artist opt-out. |
| `tracks` | id, artist_id, title, source (`audiomack`/`submitted`/`audius`/`mock`), source_ref, duration_ms, tags (text[]), artwork_url, snippet_url, link_out_url, created_at, status | `mock` rows exist only in dev databases. `snippet_url` is only for hosted audio; Audiomack stream URLs are never stored. |
| `track_snippets` | id, track_id, start_ms, end_ms, origin (`default`/`learned`/`manual`) | Allows several candidates later. |
| `track_embeddings` | track_id, model_name, model_version, vector (`vector(N)`) | Separate table so you can change models. Add only when licensed audio and a chosen model exist. |
| `interactions` | id, user_id, track_id, type, listen_ms, snippet_start_ms, ts | Append-only; indexed by user and by track. |
| `user_taste` | user_id, kind (`positive`/`negative`), vector, weight, updated_at | Stage 2+. One row per user at first. |
| `game_rounds` | id, mode (`solo`/`daily`), created_at, daily_date (nullable, unique when set) | |
| `game_round_tracks` | round_id, position, track_id | The five tracks. |
| `game_placements` | round_id, user_id, track_id, slot (1–5), placed_at | Unique (round, user, track). |
| `daily_challenges` | date (unique), round_id | Later phase. |

**Relationships:** a user has many interactions and placements; a track belongs to one artist and has many snippets, interactions and (optionally) embeddings; a round has five tracks and many players' placements.
**Store vs. retrieve:** for tracks you host or are licensed to hold, store everything. For Audiomack, store only IDs and what the terms permit, and refresh from the provider; the stream URL expires in about 10 seconds, so never store stream URLs or audio. [V/A]
**Mock vs production:** separate databases; `source = 'mock'` rows are rejected by a database constraint in production. (See the mock-data policy.)

---

## 10. Section H — Deployment, security, scalability

- **Environments:** `dev` (local, mock/fixtures), `staging` (small hosted copy), `prod`. Separate databases and secrets for each.
- **Hosting (examples, prices from vendor pages as reported in 2026):** Supabase Pro starts at $25/month and includes a $10 compute credit covering a Micro instance (Micro $10, Small $15, Medium $60) [R, several pages dated Aug–Nov 2026]; Render lists Starter web services at $7/month, Standard at $25, and small Postgres plans around $6–19 [R]. Either works for V1; neither choice is permanent.
- **Secrets:** host-managed environment variables or secret store; never commit.
- **App Store path:** paid membership ($99/year) → App Store Connect record → TestFlight (internal and external testers) → App Review. App Review will look at privacy, account deletion, and intellectual property (guideline 5.2 exists; read it before submission). [V/R]
- **Physical iPhone testing:** free Personal Team works on your own devices with 7-day signing; the paid membership removes that limit. [V]
- **Growth to thousands/tens of thousands of users:** the single FastAPI service plus one managed Postgres should be fine for thousands of users doing short, batched requests (assumption, load test to confirm). First changes at that scale: connection pooling, a larger database tier, caching feed queues, a worker for heavy jobs, CDN for snippets, rate limiting, and monitoring. Redis and queue frameworks come in only when metrics ask for them. [A]

---

## 11. Evaluation of your proposed phases

| Your phase | Assessment |
|---|---|
| 0 Feasibility | Right instinct, and the most valuable phase. It must end with a **catalog decision and a written Audiomack permission/no-permission outcome**, not just an email; frontend work should not wait for it. |
| 1 Complete frontend with placeholder songs | Good for speed and feel, but "complete" is too much before you know the playback source. A widget-based or HLS-based player changes the audio layer and may affect gestures/overlays. Build the shell with mocks, but first do a **one-day playback spike on a real iPhone** with the real candidate source. |
| 2 Music integration (before backend) | Wrong order. Provider secrets cannot live in the app, so any API-based music source needs a backend. Merge 2 and 3: a thin backend first, then music through it. |
| 3 Backend and accounts | Good; start with the smallest slice (tracks, interactions, one feed endpoint). |
| 4 Recommendation | Fine, but start with no-ML ranking; embeddings only once audio rights exist. |
| 5 Games | Games are mostly independent of the recommender. They can start in parallel once tracks and backend exist; consensus scoring and daily challenge can wait. |

**Dependencies:** Catalog/rights decision → everything audio-related. Apple membership → Sign in with Apple, TestFlight. Backend → real music and persistence. Events pipeline → recommender and game signals.
**Parallel work:** frontend shell (mock) ‖ waiting on the Audiomack answer, with an Audius spike ready as fallback ‖ artist-submission design ‖ backend skeleton.
**Postpone:** daily challenge, community consensus, multi-vector clusters, GBM, bandits for snippets (behavior-learned offsets stay simple), collaborative filtering, likes import, beat/vocal split, Redis.
**Simplify for V1:** one taste vector; fixed snippet starts; five-slot Blind Ranking without community comparison; Sign in with Apple only; one backend service.

---

## 12. Deliverable 4 — Improved roadmap

### Phase 0 — Rights and playback reality check (1–2 weeks)
- **Build:** nothing user-facing. A decision memo and two throwaway spikes.
- **Needs first:** nothing.
- **You do:** follow up with Audiomack (questions in §2.7; the first contact is done, no reply yet); read the full Audiomack Terms of Service; set the wait window after which the fallback starts; create a free Audius API key and review its terms (fallback); buy the Apple Developer membership.
- **Claude implements:** a throwaway playback spike screen using a mock HLS URL (no Audiomack call); an Audius sample-pull script (read-only) only if the fallback starts; a draft artist-submission license outline for your lawyer. No Audiomack integration code until the answer is recorded.
- **Done when:** (1) a written Audiomack answer to each Q-15 sub-question, or a documented no-reply and the founder's fallback decision; (2) Audius spike result only if the fallback starts; (3) the catalog path recorded in `decisions.md` as a new ADR superseding ADR-012; (4) after (1), a track plays from the chosen source on your iPhone including lock screen, with seek, loop and URL-expiry behavior measured.

### Phase 1 — iOS shell on mock data (2–4 weeks, parallel with Phase 0 tail)
- **Build:** theme system, three-page shell, For You playing/paused states, gesture state machine, snippet loop/fade, artwork-driven background, loading/error states.
- **Needs:** Q-01 gesture decision, Q-06/Q-07 targets.
- **You do:** run on your iPhone; judge the feel; answer gesture and accessibility questions.
- **Claude:** all SwiftUI/audio code, unit tests, mock provider isolated per policy.
- **Done when:** a full session works on a real device with mock audio; gestures are unambiguous; background/lock-screen works; tests pass; status ledger updated.

### Phase 2 — Thin backend and accounts (2–3 weeks)
- **Build:** FastAPI + Postgres, Sign in with Apple, tracks/interactions tables, feed endpoint (Stage 0 ranking), account deletion.
- **Needs:** Apple membership; hosting account; Phase 0 catalog decision.
- **You do:** create hosting and Apple accounts, approve deployments, test deletion.
- **Claude:** API, migrations, tests, deployment scripts, docs.
- **Done when:** the app signs in, loads a feed from the staging backend, records events, and deletion removes all of a test user's data.

### Phase 3 — Real catalog (2–4 weeks)
- **Build:** the Audiomack adapter to exactly the permitted scope (if granted), or artist submission flow and ingestion (fallback); snippet trimming; artwork handling.
- **Needs:** the Audiomack written answer; for the fallback, signed license text from a lawyer and first artists.
- **You do:** recruit 20–50 underground artists, get licenses, curate.
- **Claude:** submission page, ingestion scripts, admin review tool, tests.
- **Done when:** at least several hundred licensed tracks play in the app, with attribution and link-out, and takedown/opt-out works.

### Phase 4 — Games and Profile (2–3 weeks)
Blind Ranking (solo), result screen, history; Profile. Done when a full round saves and appears in history; daily challenge and community match deferred.

### Phase 5 — Recommendation stages 1–2 (3–6 weeks)
Behavior-based quality scores and learned snippet offsets; embedding benchmark on licensed audio; single-vector personalization. Done when offline held-out-like metrics beat Stage 0 and a small testing group shows higher like-rate. Then decide on later ML.

### Phase 6 — Private beta and release readiness (2–4 weeks)
TestFlight with external testers, privacy policy, accessibility pass, App Review checklist, monitoring. Done when testers complete sessions without blocking bugs and App Review requirements are met.

---

## 13. Is the "Claude Code does the coding" workflow realistic?

Yes for this project, with clear limits.

- **Claude can do mostly alone:** SwiftUI screens, gesture/state logic, audio-session plumbing, API and database code, migrations, tests, scripts, documentation, refactors, and keeping the docs/status ledger honest.
- **Needs you directly:** product decisions (gestures, scope), taste and feel judgments, recruiting artists, running the app on your iPhone and reporting what you see/hear, approving anything that spends money or touches production.
- **Needs external approval/accounts:** Apple Developer membership and capabilities; Audiomack written permission (Audius if the fallback runs); hosting accounts; App Review; legal review of artist licenses and privacy policy.
- **Needs human testing/judgment:** whether gestures feel right, whether recommendations feel good, audio gaps/fades on a real phone, accessibility with real assistive tech, whether the catalog sounds "underground enough".
- **Where you'll likely hit trouble:**
  1. Signing, provisioning and capability errors in Xcode that only appear on your machine; paste the exact error text back.
  2. Claude cannot see your screen or hear your phone unless you describe it; vague feedback ("feels off") slows iteration, so give specifics.
  3. Hidden drift: long sessions can produce code that compiles but doesn't match the design; the status ledger and tests exist to catch this.
  4. Environment limits: in a cloud chat session Claude cannot build or run iOS apps. Claude Code on your Mac can run Xcode builds, but running on your iPhone, hearing audio and judging feel still need you, and build/test commands must be verified once and recorded in `CLAUDE.md` (they are not yet).
  5. Costly mistakes with credentials: never paste secrets into chats or commit them.
  6. Scope creep — the biggest risk is quietly building the ML backend before there is a catalog or users.


---

## 14. Deliverable 5 — Personal action items (outside Claude Code)

### Do immediately
- [ ] Accept the strategic change: SoundCloud is out; Audiomack is a candidate whose permissions are unconfirmed, with artist-licensed snippets and Audius as fallbacks (§2).
- [ ] Read in full, yourself: Audiomack's Terms of Service and its API page; note anything about third-party apps, caching, players and ML.
- [ ] Follow up on your Audiomack message with the eight specific questions in §2.7, in writing; record the sender, date and exact wording of any answer. Decide the wait window after which you start the fallback. Do not assume private or non-commercial use is exempt.
- [ ] Enroll in the Apple Developer Program ($99/year) as an individual (organizations need extra paperwork, such as a D-U-N-S number [R]).
- [ ] (Fallback, only if Audiomack refuses or stalls) Create an Audius developer key, read their API terms, and ask in writing whether analysis/embeddings are allowed.
- [ ] On your Mac, confirm Xcode opens `OFFGRID.xcodeproj`, builds, and runs on your iPhone; paste any errors to Claude. Record the working commands in `CLAUDE.md`.
- [ ] Approve or reject the repo-hygiene change (`.gitignore`, untracking personal Xcode files).
- [ ] Answer open questions Q-01, Q-06, Q-07, Q-09, Q-12 in `docs/product/open-questions.md`.
- [ ] Write a list of 30–50 underground rap artists you'd want in the first catalog.
- [ ] Budget a one-time consult with an entertainment/IP lawyer (artist license, privacy policy, takedown process).

### Before music integration
- [ ] Written Audiomack outcome (and Audius outcome if the fallback ran) recorded as a new ADR superseding ADR-012.
- [ ] Lawyer-reviewed artist license/terms (submission form checkbox text).
- [ ] First 10–20 artists committed in principle.
- [ ] Decide embedding-model path: benchmark LAION-CLAP; if MERT or Essentia wins, email the licensors about commercial licenses.
- [ ] Real-iPhone playback spike passed, including lock screen.

### Before backend deployment
- [ ] Hosting account(s) with a payment method and spending alerts.
- [ ] Decision on provider (e.g., Render or Supabase) after Claude lays out the trade-offs; confirm pgvector support on the chosen plan.
- [ ] Sign in with Apple configured in your developer account (Claude will provide the click-by-click list).
- [ ] Draft privacy policy and data-retention/deletion policy.
- [ ] Separate staging and production projects; backups on.
- [ ] A support email address for artists and users.

### Before App Store submission
- [ ] Bundle ID and display name final (Q-14); App Store Connect app record created.
- [ ] App icon, screenshots, description, privacy labels, privacy policy URL, support URL.
- [ ] In-app account deletion tested end to end, including Apple token revocation.
- [ ] Accessibility review with VoiceOver and larger text.
- [ ] Artist takedown/opt-out process live; attribution and link-outs verified.
- [ ] External TestFlight beta completed; crash/bug list reviewed.
- [ ] Read App Store guideline 5.2 (intellectual property) and get the lawyer's sign-off on rights.

---

## 15. Deliverable 6 — Risk register (top 10, ranked by severity)

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| 1 | Audiomack never grants or answers: no API credentials, or no permission to play excerpts in a custom player. | Medium-High [A] | Critical: no real catalog from the primary candidate | Build on mock data meanwhile; define the wait window; fallbacks ready (artist-licensed snippets, Audius). Never scrape; the Terms bar automated retrieval except search engines [V]. |
| 2 | Permission is partial or conditional (for example no custom player, no caching, no analysis, or a fee for commercial use); access can be ended at Audiomack's discretion [V]. | Medium-High | High–Critical: design may need to change; app could be shut off | Provider-independent architecture; adapter scoped exactly to the written answer; keep link-outs; re-check the terms before each release. |
| 3 | Technical limits: 10-second stream URLs break prefetch, seek/loop may not work, rate limits are unpublished, the underground fields may be missing. | Medium-High [U] | High: the gesture-and-snippet experience degrades | One-day iPhone spike after permission; preview endpoint as an alternative; curated seed list for the underground filter; graceful skip for unplayable tracks. |
| 4 | Catalog supply and fit: Audiomack includes major-label and mainstream music, so underground rap may be hard to isolate; if the fallback is used, too few artists opt in or Audius has too little underground rap. | Medium | High: no catalog, no product | Curated artist seeds; verify fields in the spike; recruit artists early; run the Audius spike if needed. |
| 5 | Model license limits (MERT and Essentia models non-commercial). | High if chosen | Medium-High: forced rewrite or fees | Benchmark CLAP first; budget for licenses or choose accordingly. |
| 6 | Recommendation quality unproven on underground rap; cold start with few users. | Medium | Medium-High | Stage 0 curated/behavior first; measure; human review of nearest neighbors. |
| 7 | Gesture-only UI is undiscoverable or inaccessible; gesture conflicts. | Medium-High | Medium-High | Early device playtests; accessibility actions; first-run coach; revisit gestures (Q-01, Q-09). |
| 8 | Scope and complexity creep (ML, Redis, queues) before basics work; AI-agent drift. | High | Medium | Roadmap gates, status ledger, "no feature without evidence" rule; small slices. |
| 9 | Apple setup and review friction (membership, Sign in with Apple, deletion, IP). | Medium | Medium | Enroll now; follow 5.1.1(v); lawyer check on rights. |
| 10 | Legal/ethical exposure: artist takedowns, privacy, user data. | Medium | Medium-High | License text, opt-out path, data minimization, deletion cascade, privacy policy. |

---

## 16. Deliverable 7 — Estimated costs

All figures are rough. **Verified/reported prices** are marked; everything else is an assumption.

| Stage | Required | Optional | Notes |
|---|---|---|---|
| **Prototype (you + Claude, mock data)** | $0 for Xcode/free signing on your own iPhone (7-day profiles) [V]. | $99 Apple membership early (needed anyway for Sign in with Apple testing and TestFlight) [V $99; R capability]. Your AI tooling subscription is not covered here. | Local database; no hosting. |
| **Initial private testing (≈10–100 testers)** | $99/year Apple membership. Hosting about $15–40/month: e.g., Render Starter web $7 plus a small Postgres around $6–19 [R], or Supabase Pro $25 with included $10 compute credit [R]. Storage/CDN for a few hundred snippets: a few dollars. | Domain (~$10–20/year) [A]; one-time lawyer consult [A: unknown cost]. | Embedding computation on your own Mac: $0 [A]. |
| **Early public launch (hundreds–low thousands of users)** | Apple $99/year; hosting maybe $50–150/month [A] (bigger database tier — Supabase Medium is $60 [R]; larger web/worker instances $25+ each [R]); legal work for licenses/privacy (unknown, potentially the largest item). | Error monitoring, analytics, backups beyond defaults; commercial license for a model if chosen [U: "upon request"]. | Costs are driven more by legal/licensing than servers. |
| **Growth (tens of thousands of users)** | Hosting maybe several hundred dollars/month [A] (database tier, multiple API instances, CDN, workers); ongoing legal/ops (takedowns, support). | Dedicated vector store only if measured need; GPU for batch embeddings [A]. | Re-run the estimate with real traffic data. |

Audiomack's API pricing, fees and any commercial or partnership terms are not published in anything I read; all are [U] until Audiomack answers. SoundCloud costs no longer apply.

---

## 17. Deliverable 8 — Five most important next steps

1. **Follow up with Audiomack in writing using the eight questions in §2.7,** record who answered and when, and decide the wait window in advance; silence is not a yes.
2. **Read Audiomack's full Terms of Service yourself** and book the one-time lawyer consult (it also covers the fallback artist license).
3. **Enroll in the Apple Developer Program and verify the Xcode build + iPhone run,** then record the working commands in `CLAUDE.md`.
4. **Approve Phase 1 (iOS shell on mock data) now;** it does not depend on Audiomack. The playback spike on a real iPhone waits for credentials and permission, and until then uses a mock HLS source.
5. **Prepare the fallback in parallel:** a short Audius spike (underground-rap depth, terms) and the artist-submission outline, so a "no" costs days, not weeks.

---

## 18. Sources (checked 2026-11-19)

Audiomack (checked 2026-11-19)
- API documentation — https://audiomack.com/data-api/docs
- Terms of Service (read via fetch summary) — https://audiomack.com/about/terms-of-service
- Creators contact page (no API option visible) — https://creators.audiomack.com/contact-us
- Scale and catalog (trade press, reported): https://www.musicbusinessworldwide.com/audiomack-reaches-50-million-monthly-active-users-globally/ and https://www.hypebot.com/hypebot/2026/01/audiomack-passes-50-million-monthly-active-users-and-expands-artist-pro-toolkit.html
- Third-party aggregators (lower reliability; they disagree with the official page on auth): https://jentic.com/apis/audiomack, https://apis.io/apis/audiomack/audiomack-oauth-api/

SoundCloud
- API Terms of Use — https://developers.soundcloud.com/docs/api/terms-of-use
- API guide — https://developers.soundcloud.com/docs/api
- Rate limits — https://developers.soundcloud.com/docs/api/rate-limits
- LLM-context page — https://developers.soundcloud.com/docs/llm-context
- Widget API — https://developers.soundcloud.com/docs/api/html5-widget
- Help Center, public API usage — https://help.soundcloud.com/hc/en-us/articles/115003446727
- Self-serve keys for Artist Pro (2026-05-18) — https://developers.soundcloud.com/blog/vibe-coding-ai-agent-docs-self-serve-api-keys
- AAC HLS streaming change — https://developers.soundcloud.com/blog/api-streaming-urls
- Historical rate-limit post (2015) — https://developers.soundcloud.com/blog/introducing_rate_limits
- Developer GitHub notes on key issuance (older) — https://github.com/soundcloud/api

Alternatives
- Audius docs — https://docs.audius.org and https://docs.audius.co/sdk (API plans)
- Audius Open Music License — https://openaudiofoundation.org/open-music-license.pdf
- Spotify API changes (2024-11-27) — https://developer.spotify.com/blog/2024-11-27-changes-to-the-web-api; TechCrunch coverage https://techcrunch.com/2024/11/27/spotify-cuts-developer-access-to-several-of-its-recommendation-features
- Apple Music API / MusicKit — https://developer.apple.com/documentation/applemusicapi and https://developer.apple.com/documentation/musickit
- Bandcamp API — https://bandcamp.com/developer
- YouTube developer policies — https://developers.google.com/youtube/terms/developer-policies-guide
- Feed.fm Clips — https://www.feed.fm/products

Models and database
- MERT license (CC BY-NC 4.0) — https://huggingface.co/m-a-p/MERT-v1-95M and https://arxiv.org/abs/2306.00107
- LAION-CLAP (Apache-2.0 checkpoints) — https://huggingface.co/laion/clap-htsat-fused
- Essentia licensing and models — https://essentia.upf.edu/licensing_information.html and https://essentia.upf.edu/models.html
- pgvector index limits — https://access.crunchydata.com/documentation/pgvector/0.8.2/pdf/pgvector.pdf and https://supabase.com/docs/guides/ai/vector-indexes

Apple
- Account deletion requirement — https://developer.apple.com/support/offering-account-deletion-in-your-app and https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion
- Membership comparison — https://developer.apple.com/support/compare-memberships
- Media playback / audio session — https://developer.apple.com/documentation/avfoundation/configuring-your-app-for-media-playback

Hosting (prices as reported)
- Supabase pricing — https://supabase.com/pricing (and aggregators cited above)
- Render pricing — https://render.com/pricing

---

## 19. Items I could not verify

- Audiomack: every permission in Q-15; API key issuance and approval criteria; rate limits; whether the Terms of Service allow aggregation, custom players, excerpts, caching, or ML analysis; whether the API is open to new apps at all.

- (Historical) SoundCloud items are moot after the founder's decision.
- Audiomack rate limits, credential issuance process, approval criteria, fees, and whether the API is open to new private/educational apps.
- Whether Audiomack stream URLs support seeking/range requests, loops and background playback in practice; preview length; whether prefetch buffering counts as caching.
- Whether the API exposes follower and play counts needed for the underground filter.
- Audius API terms, the number of underground rap tracks on Audius, and whether analysis is permitted.
- Apple Music/MusicKit terms for preview-only playback in a discovery app.
- Quality of MERT/CLAP/Essentia embeddings for underground rap sound-alike matching.
- Exact capability limits of the free Apple Personal Team (only the 7-day profile limit was confirmed on Apple's page).
- Whether managed Postgres/auth hosts you pick support everything assumed here (pgvector, Sign in with Apple).
- Current iOS version/APIs for Liquid Glass relative to your deployment target.
