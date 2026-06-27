# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project aims to
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-06-27

### Changed

- `Daidai::Deinflection` no longer exposes the internal `conditions` bitmask;
  use `#dictionary_form?` (the raw flags remain on `Daidai::Deinflector.transform`).
- README: corrected the "Data & tables" scope, added Yomitan attribution.

## [0.1.0] - 2026-06-27

### Added

- `Daidai.conjugate(word, pos)` — forward conjugation of Japanese verbs and
  adjectives, table-driven from the JMdictDB conjugation tables.
- `Daidai::Word` interface: forms by name (`#past`, `#te`, `#potential`, …) with
  `negative:`/`polite:` keyword modifiers and chainable fluent views
  (`word.polite.negative.past`); `#[]`, `#variants`, `#conjugations`, and
  `Enumerable`.
- Optional reading: pass `reading:` to get each form's kana; kanji-only forms
  need none.
- `Daidai.conjugatable?(pos)` for a code or array of codes.
- Optional `Daidai.conjugate(word)` (POS omitted): resolves the dictionary form,
  POS and reading via the optional `kabosu` gem (Sudachi), even from inflected
  input — see `Daidai::Kabosu`. Kept lazy and out of the default dependency set.
- `Daidai.deinflect(word)` — pure-Ruby, offline deinflection: turns an inflected
  surface form back into its dictionary form(s) and names each inflection (the
  inverse of `#conjugate`). Ported from Yomitan's Japanese language transforms;
  also covers colloquial contractions (てる, ちゃう, …). See `Daidai::Deinflector`.

[Unreleased]: https://github.com/davafons/daidai/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/davafons/daidai/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/davafons/daidai/releases/tag/v0.1.0
