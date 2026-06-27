<h1 align="center">Daidai</h1>

<p align="center">
  <a href="https://rubygems.org/gems/daidai"><img src="https://img.shields.io/gem/v/daidai" alt="Gem Version"></a>
  <a href="https://github.com/davafons/daidai/actions/workflows/edge.yml"><img src="https://github.com/davafons/daidai/actions/workflows/edge.yml/badge.svg" alt="CI"></a>
  <a href="https://github.com/davafons/daidai/blob/main/LICENSE"><img src="https://img.shields.io/github/license/davafons/daidai" alt="License"></a>
  <a href="https://rubygems.org/gems/daidai"><img src="https://img.shields.io/gem/dt/daidai" alt="Downloads"></a>
</p>

Pure-Ruby Japanese verb and adjective conjugation. Daidai (橙) is a table-driven, faithful port of [jconj](https://gitlab.com/yamagoya/jconj)'s algorithm built on the [JMdictDB](https://www.edrdg.org/) conjugation tables (Stuart McGraw / Jim Breen's [EDRDG](https://www.edrdg.org/)). No native extension, no runtime services — just the tables and a small, app-friendly API.

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

Pass a dictionary-form word and its [JMdict part-of-speech code](https://www.edrdg.org/jmdictdb/cgi-bin/edhelpq.py?svc=jmdict&sid=#kw_pos). `Daidai.conjugate` returns a `Daidai::Result`, or `nil` when nothing is conjugatable.

```ruby
require "daidai"

# Godan verb (v5k)
result = Daidai.conjugate(kanji: "書く", reading: "かく", pos: "v5k")
result.pos           # => "v5k"
result.kind          # => :godan
result.conjugations  # => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
result.name(2)       # => "Past (~ta)"

# Ichidan verb (v1)
Daidai.conjugate(kanji: "食べる", reading: "たべる", pos: "v1").kind   # => :ichidan

# する — a word with no kanji writing (pass kanji: nil)
Daidai.conjugate(kanji: nil, reading: "する", pos: "vs-i").kind        # => :suru

# 来る (vk)
Daidai.conjugate(kanji: "来る", reading: "くる", pos: "vk").kind        # => :kuru

# i-adjective (adj-i)
Daidai.conjugate(kanji: "高い", reading: "たかい", pos: "adj-i").kind   # => :i_adjective

# na-adjective (adj-na) — conjugates through the copula だ
Daidai.conjugate(kanji: "静か", reading: "しずか", pos: "adj-na").kind  # => :na_adjective
```

### Reading the forms

`Result#forms` is the full paradigm — every generated `Daidai::Form`:

```ruby
result = Daidai.conjugate(kanji: "書く", reading: "かく", pos: "v5k")

form = result.forms.first
form.conjugation  # => 1            - conjugation id
form.name         # => "Non-past"   - human-readable name
form.kanji        # => "書く"        - inflected kanji writing (may be nil)
form.reading      # => "かく"        - inflected kana
form.text         # => "書く"        - kanji when present, otherwise the kana
form.onum         # => 1            - variant number for forms with alternatives
form.negative?    # => false
form.polite?      # => false
form.primary?     # => true         - the primary variant (onum == 1)
```

### Reading a grid

`Result#grid` slices one conjugation into the four politeness/negation cells, keyed by `[negative, polite]` and limited to the primary variant — ideal for rendering a conjugation table:

```ruby
result = Daidai.conjugate(kanji: "書く", reading: "かく", pos: "v5k")

grid = result.grid(1)                # 1 = Non-past
grid[[false, false]].text            # => "書く"     - plain affirmative
grid[[false, true]].text             # => "書きます"  - polite affirmative
grid[[true, false]].text             # => "書かない"  - plain negative
grid[[true, true]].text              # => "書きません" - polite negative

result.grid(2)[[true, false]].text   # 2 = Past (~ta) => "書かなかった"
```

The conjugation ids are stable:

| id | Name | id | Name |
|----|------|----|------|
| 1 | Non-past | 8 | Causative-Passive |
| 2 | Past (~ta) | 9 | Volitional |
| 3 | Conjunctive (~te) | 10 | Imperative |
| 4 | Provisional (~eba) | 11 | Conditional (~tara) |
| 5 | Potential | 12 | Alternative (~tari) |
| 6 | Passive | 13 | Continuative (~i) |
| 7 | Causative | | |

### Checking conjugatability

`Daidai.conjugatable?` takes a single JMdict code or an array of them, and is true when at least one is conjugatable. Useful for deciding whether to show a conjugation table for a dictionary entry:

```ruby
Daidai.conjugatable?("v5k")            # => true
Daidai.conjugatable?("n")              # => false
Daidai.conjugatable?(["n", "v1"])      # => true  - first conjugatable code wins
```

When `pos` is an array, `Daidai.conjugate` likewise picks the first conjugatable code.

## Data & tables

All of the linguistic knowledge lives in four tab-separated tables vendored under `lib/daidai/resources/`, copied verbatim from jconj:

| File | Contents |
|------|----------|
| `conj.csv` | conjugation ids and their names |
| `conjo.csv` | okurigana rules (one per pos / conjugation / negative / polite / variant) |
| `conotes.csv` | usage notes attached to conjugations |
| `kwpos.csv` | JMdict part-of-speech keywords and their numeric ids |

The conjugator just applies these rules: it drops the citation-form okurigana, applies any euphonic change, and appends the conjugated ending. Nothing is hard-coded per verb, so keeping the tables current keeps the whole gem current.

Refresh the vendored tables from upstream jconj with:

```sh
rake daidai:sync
```

This downloads the latest `conj.csv`, `conjo.csv`, `conotes.csv`, and `kwpos.csv` from the [jconj repository](https://gitlab.com/yamagoya/jconj) and writes them into `lib/daidai/resources/`. Review the diff before committing.

## Data & attribution

The conjugation algorithm and tables are not original to Daidai. They come from:

- **jconj** — <https://gitlab.com/yamagoya/jconj>, by Stuart McGraw, which Daidai ports to Ruby.
- **JMdictDB / JMdict** — the dictionary database and part-of-speech taxonomy maintained by Jim Breen's **Electronic Dictionary Research and Development Group (EDRDG)**, <https://www.edrdg.org/>.

Because the upstream work is GPL-licensed, Daidai inherits that lineage and is distributed under the **GPL-3.0** license. The JMdict/JMdictDB data is used under the EDRDG licence; please retain the attribution above and the `NOTICE` file in any redistribution.

## Development

```sh
bundle install

bundle exec rake test    # Run the test suite
bundle exec rake lint    # RuboCop
```

To refresh the vendored conjugation tables from upstream, see `rake daidai:sync` above.

## License

Daidai is released under the [GPL-3.0](LICENSE) license, in keeping with its jconj / JMdictDB lineage. See `LICENSE` and `NOTICE` for the full terms and upstream attribution.
