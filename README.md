<h1 align="center">Daidai</h1>

<p align="center">
  <a href="https://rubygems.org/gems/daidai"><img src="https://img.shields.io/gem/v/daidai" alt="Gem Version"></a>
  <a href="https://github.com/davafons/daidai/actions/workflows/ci.yml"><img src="https://github.com/davafons/daidai/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://github.com/davafons/daidai/blob/main/LICENSE"><img src="https://img.shields.io/github/license/davafons/daidai" alt="License"></a>
  <a href="https://rubygems.org/gems/daidai"><img src="https://img.shields.io/gem/dt/daidai" alt="Downloads"></a>
</p>

Pure-Ruby Japanese verb and adjective conjugation. Daidai (橙) is table-driven: all the grammar lives in the conjugation tables from [JMdictDB](https://gitlab.com/yamagoya/jmdictdb) (Jim Breen's [EDRDG](https://www.edrdg.org/)) — the same tables that power EDRDG's live conjugator — applied by a faithful Ruby port of [jconj](https://gitlab.com/yamagoya/jconj)'s algorithm. No native extension, no runtime services — just the tables and a small, app-friendly API.

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

The conjugation tables ship vendored inside the gem, so there is nothing to download — conjugation works offline out of the box.

## Usage

Pass a dictionary-form word and its [JMdict part-of-speech code](https://www.edrdg.org/jmdictdb/cgi-bin/edhelpq.py?svc=jmdict&sid=#kw_pos). `Daidai.conjugate` returns a `Daidai::Word`, or `nil` when nothing is conjugatable.

```ruby
require "daidai"

verb = Daidai.conjugate("書く", "v5k")   # word + JMdict POS code

verb.past          # => #<Daidai::Form past: 書いた>
verb.past.to_s     # => "書いた"   (Form#to_s — works directly in "#{...}")
verb.te            # => 書いて
verb.potential     # => 書ける
verb.volitional    # => 書こう
```

The `reading` is **optional** — conjugation only ever rewrites the okurigana, which is already in the surface form, so the kanji forms need no reading. Pass one only when you also want each form's kana:

```ruby
verb = Daidai.conjugate("書く", "v5k", reading: "かく")
verb.past.kanji    # => "書いた"
verb.past.reading  # => "かいた"

# A kana-only word is its own reading:
Daidai.conjugate("する", "vs-i").past.to_s   # => "した"
```

### Negative & polite

Polarity and formality are named — never boolean tuples. Use keyword modifiers (canonical) or chainable fluent views (sugar):

```ruby
verb = Daidai.conjugate("書く", "v5k")

# keyword modifiers
verb.non_past(negative: true)            # => 書かない
verb.past(polite: true)                  # => 書きました
verb.past(negative: true, polite: true)  # => 書きませんでした

# fluent views — read like grammar, and chain
verb.polite.past                # => 書きました
verb.negative.non_past          # => 書かない
verb.polite.negative.non_past   # => 書きません
```

### The forms

A `Daidai::Word` is `Enumerable` and exposes every form **by name** — no integer ids:

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

`Daidai.conjugatable?` takes a single JMdict code or an array, and is true when at least one is conjugatable — handy for deciding whether to show a conjugation table for a dictionary entry:

```ruby
Daidai.conjugatable?("v5k")            # => true
Daidai.conjugatable?("n")              # => false
Daidai.conjugatable?(["n", "v1"])      # => true   - first conjugatable code wins
```

When `pos` is an array, `Daidai.conjugate` likewise picks the first conjugatable code.

## Data & tables

All of the linguistic knowledge lives in four tab-separated tables vendored under `lib/daidai/resources/`, taken from **JMdictDB** (the maintained home of these tables; jconj is the standalone reference implementation Daidai ports):

| File | Contents |
|------|----------|
| `conj.csv` | conjugation ids and their names |
| `conjo.csv` | okurigana rules (one per pos / conjugation / negative / polite / variant) |
| `conotes.csv` | usage notes attached to conjugations |
| `kwpos.csv` | JMdict part-of-speech keywords and their numeric ids |

The conjugator just applies these rules: it drops the citation-form okurigana, applies any euphonic change, and appends the conjugated ending. Nothing is hard-coded per verb, so keeping the tables current keeps the whole gem current. (Japanese conjugation grammar is stable — these tables change rarely.)

Refresh the vendored tables from upstream with:

```sh
rake daidai:sync
```

This downloads the latest `conj.csv`, `conjo.csv`, `conotes.csv`, and `kwpos.csv` from the [JMdictDB repository](https://gitlab.com/yamagoya/jmdictdb) and writes them into `lib/daidai/resources/`. Review the diff before committing. `rake daidai:check_resources` fails if the bundled tables have drifted from upstream.

## Data & attribution

The conjugation algorithm and tables are not original to Daidai. They come from:

- **JMdictDB** — <https://gitlab.com/yamagoya/jmdictdb>, by Stuart McGraw: the actively-maintained home of the conjugation tables and part-of-speech taxonomy, under Jim Breen's **Electronic Dictionary Research and Development Group (EDRDG)**, <https://www.edrdg.org/>.
- **jconj** — <https://gitlab.com/yamagoya/jconj>: the standalone, table-based conjugator whose algorithm Daidai ports to Ruby.

Because the upstream work is GPL-licensed, Daidai inherits that lineage and is distributed under the **GPL-3.0** license. The JMdict/JMdictDB data is used under the EDRDG licence; please retain the attribution above and the `NOTICE` file in any redistribution.

## Development

```sh
bundle install

bundle exec rake test    # Run the test suite
bundle exec rake lint    # RuboCop
bundle exec rake         # lint + test (default)
```

To refresh the vendored conjugation tables from upstream, see `rake daidai:sync` above.

## License

Daidai is released under the [GPL-3.0](LICENSE) license, in keeping with its JMdictDB / jconj lineage. See `LICENSE` and `NOTICE` for the full terms and upstream attribution.
