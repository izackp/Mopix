## 2026-07-20 — Tennis branch setup

- User clarified that implementation is not PL's job and asked for a new branch.
- Created and switched to `claude-tennis-game`.
- No tennis source or product-spec implementation changes were made.
- Current tennis implementation remains a static court shell; `swift build --product Tennis` fails because `TennisScene.swift` references unavailable `RendererClient`.
