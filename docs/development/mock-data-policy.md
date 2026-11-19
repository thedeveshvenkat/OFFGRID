# OFFGRID — Mock Data Policy

Mock data exists so the app can be built and tested without any real music provider (Audiomack access is unconfirmed, Q-15; SoundCloud is ruled out). It must never be mistaken for, or mixed with, production data.

## Rules
1. Location: client mocks only in `OFFGRID/Mocks/`; backend fixtures only in `backend/fixtures/`. No mock data anywhere else.
2. Unmistakably fake: IDs start with `mock_`; titles and artist names are invented and obviously fictional; no real provider IDs, URLs, artists, or artwork (Audiomack or any other).
3. Audio: placeholder audio must be generated for the purpose or otherwise cleared for use. Never copy audio obtained from any provider into the repo.
4. One switch: the app selects its `TrackProvider` in a single place. Debug builds may default to the mock provider; release builds default to the remote provider and cannot select the mock one.
5. Never seed or load fixtures into a production database; fixture loading scripts refuse to run against a non-development environment.
6. Mock screens show no claim of real recommendation behavior. Anything powered by mock data is described as such in `status.md`.
7. Tests use mocks; production data is not used in automated tests.
