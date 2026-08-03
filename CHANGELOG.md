# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project aims to
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.5] - 2026-08-03

### Removed

- `-気味`, added in 0.2.4. It reached 疲れ気味 → 疲れる by deriving from `-たい`, but
  気味 is not that kind of suffix: after a noun (風邪気味, 疲れ気味, 遅れ気味, which is
  how Sudachi reads all three) both halves are already dictionary words and 風邪気味
  is an entry in its own right, so the rule only ever competed with a better
  answer. `-がち` stays: 忘れがち has no noun reading to compete with.

## [0.2.4] - 2026-08-03

### Added

- The rest of the must / must not / may / need not set: `permission` (〜てもいい,
  〜てもかまわない) and `exemption` (〜なくてもいい). Learners meet the four together,
  so they now deinflect alike.
- The remaining て-auxiliaries beside `-おく` and `-しまう`: `-てみる`, `-てある`,
  `-ていく`, `-てくる`. `conditionsIn` is the auxiliary's own verb class, so it may
  conjugate and the verb is still reached (読んでみた, 読んでみたい).
- `-べき`, and the 連用形 suffixes `-ながら`, `-つつ`, `-やすい`, `-にくい`. The last two
  are i-adjectives, so 読みやすかった resolves too.
- Aspectual compound verbs `-はじめる`/`-始める`, `-つづける`/`-続ける`,
  `-おわる`/`-終わる`, in both spellings.
- The benefactives, who the action is done for: `-てあげる`, `-てやる`,
  `-てさしあげる`, `-てくれる`, `-てくださる`, `-てもらう`, `-ていただく`.
- `-てください` (and 〜てちょうだい). ください is くださる's irregular imperative and does
  not conjugate further, so `-てくださる` never matched the commonest polite request
  in the language.
- Further 連用形 suffixes: `-がち`, `-っぱなし`, `-かねる`. (`-気味` was added here too
  and withdrawn in 0.2.5.)

  〜かける is excluded for the same reason as 〜だす: the substring にかける strips to
  にる (煮る), a real word, so it would mis-read 気にかける.

  〜だす, 〜なおす and 〜きる are deliberately absent: they lexicalise, and the
  dictionary already carries them. 見直す is "to review", not "to see again", and
  every 〜だす compound checked (泣き出す, 降り出す, 言い出す, 走り出す, 笑い出す,
  動き出す) is a JMdict entry already. A rule wins nothing there, while 出す as a
  main verb is everywhere: it read 外に出す as に出す ("煮出す") and 声に出して as にる.

### Fixed

- A shorter construction no longer shadows a longer one. 〜てはいけない matches inside
  〜なくてはいけない and 〜てもいい inside 〜なくてもいい, so both readings were reachable
  and a consumer picking by chain length could get `prohibition` for an obligation.
  The negated forms now land straight on ない, which is both shorter and faithful
  (〜なくて is ない's te-form), so the right label wins deterministically.
- The obligation and prohibition constructions resolve when their helper is itself
  inflected (行かなければならなかった, 食べてはいけなかった). They were gated to the
  outermost layer; gating on `adj-i` instead lets ならない/いけない deinflect first.
  This removes the limitation recorded under 0.2.3.

## [0.2.3] - 2026-08-03

### Added

- Deinflection of the obligation and prohibition constructions, which no rule
  reached before: 行かなければならない, 行かなくてはいけない, 行かないといけない,
  行かねばならない, 行かなきゃならない, 行かなくちゃ (and the ～ません/～だめ variants)
  now resolve to 行く, and 食べてはいけない, 読んではいけない, 遊んじゃだめ to their
  base. Each rule strips only its helper and hands the rest back to a rule that
  already existed, so the chain shows the whole derivation
  (`["obligation", "-ば", "negative"]`) instead of one opaque step, and the
  irregulars come along for free.

  They are labelled as the opposites they are: `obligation (must)` negates the
  verb and then the helper (行かなければならない, "there is no not-going"), while
  `prohibition (must not)` leaves the verb plain (食べてはいけない, "eating won't
  do"). Yomitan's rule set has neither, treating both as multi-word grammar
  rather than inflection.

  The helper's own inflection is not covered yet: 行かなければならなかった (past) and
  行かなければならなくて still fall through, because the rules match the construction
  only as the outermost layer.

## [0.2.2] - 2026-07-25

### Added

- Deinflection of the negative te-form 〜ないで (食べないで, 行かないで, 読まないで →
  dictionary form). Yomitan's rule set has no entry for it; daidai adds one,
  resolving 〜ないで through the plain negative (〜ない) to the base across every
  verb class. (〜なくて already resolved via the -て + negative chain.) The
  prohibitive 〜な (食べるな) is deliberately left out — 〜な is too ambiguous
  (sentence particle, na-adjective) for a safe rule.

## [0.2.1] - 2026-07-25

### Fixed

- `Daidai.conjugate` now produces the correct godan-u negative conditional
  (買う → 買わなかったら). The upstream JMdictDB `conjo.csv` stores this one cell
  without the な (買わかったら); `Tables::CONJO_ERRATA` corrects it at load, so the
  vendored tables stay byte-identical to upstream while every godan-u verb's
  negative ~tara comes out right.

## [0.2.0] - 2026-06-27

### Added

- `Daidai::Deinflection#labels` and `Daidai::Deinflector.label(name)`: friendly
  English names for deinflection rules ("-いる" → "progressive", "-て" →
  "te-form"). daidai now owns the inflection-naming vocabulary so consumers
  localise it rather than each maintaining their own map.

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

[Unreleased]: https://github.com/davafons/daidai/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/davafons/daidai/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/davafons/daidai/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/davafons/daidai/releases/tag/v0.1.0
