<h1 align="center">Daidai</h1>

<p align="center">
  <a href="https://rubygems.org/gems/daidai"><img src="https://img.shields.io/gem/v/daidai" alt="Gem Version"></a>
  <a href="https://github.com/basecamp/gh-signoff"><img src="https://img.shields.io/badge/CI-signoff-blue" alt="Signoff"></a>
  <a href="https://github.com/davafons/daidai/blob/main/LICENSE"><img src="https://img.shields.io/github/license/davafons/daidai" alt="License"></a>
  <a href="https://rubygems.org/gems/daidai"><img src="https://img.shields.io/gem/dt/daidai" alt="Downloads"></a>
</p>

Pure-Ruby Japanese verb and adjective conjugation. Daidai (橙) is table-driven: all the grammar lives in the conjugation tables from [JMdictDB](https://gitlab.com/yamagoya/jmdictdb) (Jim Breen's [EDRDG](https://www.edrdg.org/)), the same tables that power EDRDG's live conjugator, applied by a faithful Ruby port of [jconj](https://gitlab.com/yamagoya/jconj)'s algorithm. No native extension, no runtime services, just the tables and a small, app-friendly API.

```ruby
verb = Daidai.conjugate("書く", "v5k")    # a word + its JMdict part of speech

verb.past                        # => 書いた
verb.past(polite: true)          # => 書きました
verb.te                          # => 書いて
verb.non_past(negative: true)    # => 書かない
verb.polite.negative.past        # => 書きませんでした   (fluent, and chainable)

# Don't know the part of speech? Let kabosu (Sudachi) resolve it, even from an
# already-inflected word:
Daidai.conjugate("食べている").word   # => "食べる"
```

## Installation

- Ruby >= 3.1

Add to your Gemfile:

```ruby
gem "daidai"
```

Then install:

```sh
bundle install
```

The conjugation tables ship vendored inside the gem, so there is nothing to download; conjugation works offline out of the box.

## Usage

Pass a dictionary-form word and its [JMdict part-of-speech code](https://www.edrdg.org/jmdictdb/cgi-bin/edhelpq.py?svc=jmdict&sid=#kw_pos). `Daidai.conjugate` returns a `Daidai::Word`, or `nil` when nothing is conjugatable.

```ruby
require "daidai"

verb = Daidai.conjugate("書く", "v5k")   # word + JMdict POS code

verb.past          # => #<Daidai::Form past: 書いた>
verb.past.to_s     # => "書いた"   (Form#to_s, works directly in "#{...}")
verb.te            # => 書いて
verb.potential     # => 書ける
verb.volitional    # => 書こう
```

The `reading` is **optional**: conjugation only ever rewrites the okurigana, which is already in the surface form, so the kanji forms need no reading. Pass one only when you also want each form's kana:

```ruby
verb = Daidai.conjugate("書く", "v5k", reading: "かく")
verb.past.kanji    # => "書いた"
verb.past.reading  # => "かいた"

# A kana-only word is its own reading:
Daidai.conjugate("する", "vs-i").past.to_s   # => "した"
```

### Negative & polite

Polarity and formality are named. Use keyword modifiers (canonical) or chainable fluent views (sugar):

```ruby
verb = Daidai.conjugate("書く", "v5k")

# keyword modifiers
verb.non_past(negative: true)            # => 書かない
verb.past(polite: true)                  # => 書きました
verb.past(negative: true, polite: true)  # => 書きませんでした

# fluent views, read like grammar, and chain
verb.polite.past                # => 書きました
verb.negative.non_past          # => 書かない
verb.polite.negative.non_past   # => 書きません
```

### The forms

A `Daidai::Word` is `Enumerable` and exposes every form **by name**, with no integer ids:

```ruby
Daidai::FORMS.keys
# => [:non_past, :past, :te, :provisional, :potential, :passive, :causative,
#     :causative_passive, :volitional, :imperative, :conditional, :alternative, :stem]

verb.conjugations                    # => the form names present for this word
verb.forms                           # => every Daidai::Form
verb.each { |form| ... }             # Enumerable
verb[:past, polite: true]            # dynamic access (== verb.past(polite: true))
verb.variants(:te, negative: true)   # every accepted variant: 書かなくて, 書かないで
```

A `Daidai::Form`:

```ruby
form = verb.past(polite: true)
form.to_s       # => "書きました"   - the kanji form, or the kana if there is no kanji
form.kanji      # => "書きました"
form.reading    # => nil unless a reading was supplied
form.name       # => :past
form.label      # => "Past"
form.negative?  # => false
form.polite?    # => true
```

### Word classes

```ruby
Daidai.conjugate("食べる", "v1").kind     # => :ichidan
Daidai.conjugate("来る", "vk").kind        # => :kuru          (来る / くる both handled)
Daidai.conjugate("高い", "adj-i").kind     # => :i_adjective
Daidai.conjugate("静か", "adj-na").kind    # => :na_adjective  (conjugated via the copula だ)
```

### Checking conjugatability

`Daidai.conjugatable?` takes a single JMdict code or an array, and is true when at least one is conjugatable. Handy for deciding whether to show a conjugation table for a dictionary entry:

```ruby
Daidai.conjugatable?("v5k")            # => true
Daidai.conjugatable?("n")              # => false
Daidai.conjugatable?(["n", "v1"])      # => true   - first conjugatable code wins
```

When `pos` is an array, `Daidai.conjugate` likewise picks the first conjugatable code.

## Conjugate by word alone (optional)

Don't have the part of speech? Omit it, and Daidai uses the optional [`kabosu`](https://github.com/davafons/kabosu) gem (Ruby bindings for the [Sudachi](https://github.com/WorksApplications/sudachi.rs) morphological analyzer) to resolve the dictionary form, POS and reading from any input, **including inflected ones**:

```ruby
Daidai.conjugate("食べている").word   # => "食べる"   (progressive → its dictionary verb)
Daidai.conjugate("行った").word       # => "行く"     (irregular v5k-s, correctly identified)
Daidai.conjugate("高くない").word     # => "高い"     (negative adjective → adj-i)
Daidai.conjugate("勉強した").word     # => "勉強"     (noun + する → vs)
Daidai.conjugate("猫")               # => nil        (not conjugatable)
```

This resolves the word so you can conjugate it (forward inflection from a dictionary entry). To go the other way and *name* the inflection ("…is the progressive of…"), see [Deinflection](#deinflection-inflected-form-to-dictionary-form) below. For lemma lookup in a larger app you likely already have a tokenizer; this is a convenience for the conjugation use case.

`kabosu` and a Sudachi dictionary are **not** dependencies of Daidai; the gem stays pure Ruby. Add them only if you want this path:

```ruby
# Gemfile
gem "daidai"
gem "kabosu"
```

```sh
bundle exec rake kabosu:install   # download a Sudachi dictionary (one-time)
```

Without them, the POS-less path raises `Daidai::Kabosu::MissingDependency`. The escape hatch is always to pass the POS yourself, and then kabosu never loads:

```ruby
Daidai.conjugate("食べる", "v1")   # pure Ruby, no kabosu
```

## Deinflection (inflected form to dictionary form)

`Daidai.deinflect` is the inverse of `conjugate`: give it an inflected surface
form and it returns the dictionary form(s) it could come from, **naming each
inflection** along the way. It is pure Ruby and offline, with no Sudachi/kabosu
needed, and it covers colloquial contractions (てる, ちゃう, とく, …):

```ruby
Daidai.deinflect("食べてる")
# includes #<Daidai::Deinflection 食べる [-いる, -て]>   (the progressive of 食べる)

Daidai.deinflect("読まなかった")
# includes #<Daidai::Deinflection 読む [-た, negative]>   (negative past of 読む)
```

Each result is a `Daidai::Deinflection`:

```ruby
d = Daidai.deinflect("食べてる").find { |x| x.term == "食べる" }
d.term              # => "食べる"             (the candidate dictionary form)
d.inflections       # => ["-いる", "-て"]      (rule names, surface to dictionary)
d.dictionary_form?  # => true                (chain lands on a known dictionary form)
d.to_s              # => "食べる [-いる, -て]"
```

Deinflection is rule-based and **dictionary-free**, so it returns *every* base
form the rules can reach — many of which are not real words (食べてる also yields
食べつ as a hypothetical potential). It is meant to feed a dictionary lookup: keep
the candidates whose `term` is a real entry. If you have no dictionary, filtering
to `dictionary_form?` candidates keeps the plausible lemmas.

This pairs naturally with a dictionary like JMdict: deinflect the query, look up
each candidate `term`, and you have the lemma, its part of speech, and the named
inflection — without a morphological analyzer. (For a single authoritative lemma
+ reading from arbitrary text, including full sentences, the kabosu path above is
still the tool; the two are complementary.)

The rule set is ported from [Yomitan](https://github.com/yomidevs/yomitan)'s
Japanese language transforms and is vendored as JSON under
`lib/daidai/resources/`. Both Yomitan and Daidai are GPL-3.0; see `NOTICE`.

## Data & tables

All of the linguistic knowledge lives in four tab-separated tables vendored under `lib/daidai/resources/`, taken from **JMdictDB** (the maintained home of these tables; jconj is the standalone reference implementation Daidai ports):

| File | Contents |
|------|----------|
| `conj.csv` | conjugation ids and their names |
| `conjo.csv` | okurigana rules (one per pos / conjugation / negative / polite / variant) |
| `conotes.csv` | usage notes attached to conjugations |
| `kwpos.csv` | JMdict part-of-speech keywords and their numeric ids |

The conjugator just applies these rules: it drops the citation-form okurigana, applies any euphonic change, and appends the conjugated ending. Nothing is hard-coded per verb, so keeping the tables current keeps the whole gem current. (Japanese conjugation grammar is stable, so these tables change rarely.)

Refresh the vendored tables from upstream with:

```sh
rake daidai:sync
```

This downloads the latest `conj.csv`, `conjo.csv`, `conotes.csv`, and `kwpos.csv` from the [JMdictDB repository](https://gitlab.com/yamagoya/jmdictdb) and writes them into `lib/daidai/resources/`. Review the diff before committing. `rake daidai:check_resources` fails if the bundled tables have drifted from upstream.

## Data & attribution

The conjugation algorithm and tables are not original to Daidai. They come from:

- **JMdictDB** (<https://gitlab.com/yamagoya/jmdictdb>), by Stuart McGraw: the actively-maintained home of the conjugation tables and part-of-speech taxonomy, under Jim Breen's **Electronic Dictionary Research and Development Group (EDRDG)**, <https://www.edrdg.org/>.
- **jconj** (<https://gitlab.com/yamagoya/jconj>): the standalone, table-based conjugator whose algorithm Daidai ports to Ruby.

Because the upstream work is GPL-licensed, Daidai inherits that lineage and is distributed under the **GPL-3.0** license. The JMdict/JMdictDB data is used under the EDRDG licence; please retain the attribution above and the `NOTICE` file in any redistribution.

## Development

```sh
bundle install

bundle exec rake test    # Run the test suite
bundle exec rake lint    # RuboCop
bundle exec rake         # lint + test (default)
```

### Signing off

This project uses [gh-signoff](https://github.com/basecamp/gh-signoff) instead of cloud CI: you run the checks locally and sign off on the commit, which sets a `signoff` status check that branch protection requires.

```sh
gh extension install basecamp/gh-signoff   # one-time
bundle exec rake signoff                   # runs lint + test, signs off ONLY if they pass
```

`rake signoff` makes `lint` and `test` prerequisites, so it won't sign off a red commit. (Running `gh signoff create -f` by hand skips that gate; gh-signoff is trust-based.) The `-f` flag is needed because jj leaves git's HEAD detached.

`gh signoff install` configures `main` to require the signoff status. To refresh the vendored conjugation tables from upstream, see `rake daidai:sync` above.

## License

Daidai is released under the [GPL-3.0](LICENSE) license, in keeping with its JMdictDB / jconj lineage. See `LICENSE` and `NOTICE` for the full terms and upstream attribution.
