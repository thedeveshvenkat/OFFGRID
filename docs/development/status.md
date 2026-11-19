# OFFGRID — Implementation Status

The single source of truth for what exists. A row moves to "Done" only with evidence: what was run, on what, and the result. Last updated: 2026-11-19 (Milestones 0.1 and 0.2; no application code changed).

States: Not started · In progress · Done (tested) · Blocked.

## Roadmap milestones
| Milestone | State | Evidence / notes |
|---|---|---|
| 0.1 Repo hygiene | Done | 2026-11-19, by Claude. (1) `.gitignore` added (xcuserdata, `*.xcuserstate`, `.DS_Store`, DerivedData, build output, SwiftPM). (2) `git rm --cached` on `OFFGRID.xcodeproj/project.xcworkspace/xcuserdata/deveshv.xcuserdatad/WorkspaceSettings.xcsettings` and `OFFGRID.xcodeproj/xcuserdata/deveshv.xcuserdatad/xcschemes/xcschememanagement.plist`; both still exist on disk (checked with `ls`), and `git status --ignored` lists the remaining xcuserdata files as ignored. Committed as a "repo hygiene" commit. (3) `CLAUDE.md`, `README.md`, and `docs/` committed in a separate "documentation" commit. (4) A clean simulator build, `xcodebuild -project OFFGRID.xcodeproj -scheme OFFGRID -destination 'platform=iOS Simulator,name=iPhone 17' clean build` (Xcode 27.2), gave `** CLEAN SUCCEEDED **` and `** BUILD SUCCEEDED **`; the only warning was the AppIntents metadata note. The built `OFFGRID.app` Info.plist has `CFBundleIdentifier` = `com.offgrid.app` and `CFBundleDisplayName` = `Offgrid`. The command is recorded in `CLAUDE.md`. The test command is not part of 0.1: it moved to the start of 1A (founder decision, ADR-014). Nothing pushed. |
| 0.2 Decisions | Done | 2026-11-19. Founder answered Q-06 (iOS 26.0; Claude checked that the SDK marks Liquid Glass APIs available from iOS 26.0) and Q-07 (iPhone only), both in ADR-013, and Q-14 (keep bundle ID and name, ADR-018). Q-08 deferred to 1B and Q-13 to 1C (ADR-019). Also decided: Q-01 gestures (ADR-015), Q-09 direction (ADR-016), test framework (ADR-014), `MyApp` rename approved (ADR-017). Logged in `decisions.md` and `open-questions.md`. The deployment-target and device-family changes in the project file are not applied yet; they're scheduled for the start of 1A. |
| 0.3 Audiomack access | Pending (external) | No reply from Audiomack as of 2026-11-19. Does not block 1A, 1B, or Phase 2. |
| 0.4 Seed catalog / embedding benchmark | Waived for prototype | Per roadmap, unless 0.3 permits. |
| 1A iOS shell on mock data | Not started | Waiting for founder approval to begin. |

## Project foundation
| Item | State | Evidence / notes |
|---|---|---|
| Xcode project (`OFFGRID.xcodeproj`, bundle ID `com.offgrid.app`) | Exists; builds | Simulator build verified 2026-11-19 (see 0.1). Settings still say `IPHONEOS_DEPLOYMENT_TARGET` = 27.2 and `TARGETED_DEVICE_FAMILY` = 1,2, until 1A starts. The `OFFGRID` scheme is auto-generated and not shared yet (that happens in 1A). |
| App source | Template only | `MyApp.swift` and `ContentView.swift` are unmodified template code ("Hello, world!"). |
| Git repo / GitHub remote | Exists | Branch `main`, remote `origin`. Docs and hygiene commits are local only; not pushed (founder instruction). |
| Tests | None | No test target; created at the start of 1A (ADR-014). |
| Backend | None | Directory does not exist. |
| Design doc | Exists | `docs/OFFGRID DESIGN DOC.pdf`, v0.2 draft. |
| Development documentation | Committed; founder decisions applied | Product requirements, architecture, decisions, roadmap, testing plan, mock policy, open questions, `CLAUDE.md`. |

## Product features
All Not started: For You (playing/paused states), gestures, snippet playback, themes, Games shell, Blind Ranking, Profile, recommendation system, ingestion pipeline, accounts.

## Blocked on external answers
Anything depending on a real music provider (Q-15): Audiomack API access and permissions are unconfirmed (contacted, no reply as of 2026-11-19); SoundCloud is ruled out. Blocked: real catalog, in-app playback source, ingestion. Audio analysis and embeddings are exploratory only and not planned for the prototype. Mock/demo-track development is NOT blocked.
