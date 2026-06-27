# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project aims to
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/davafons/daidai/commits/main
