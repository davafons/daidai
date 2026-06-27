# frozen_string_literal: true

require_relative "tables"
require_relative "result"

module Daidai
  # Turns a dictionary-form word + its JMdict part-of-speech into the full
  # conjugation paradigm. This is a faithful Ruby port of jconj's table-driven
  # algorithm (Stuart McGraw / EDRDG; GPL) — all the linguistic knowledge lives
  # in the vendored tables, this just applies them.
  module Conjugator
    # The four (negative?, polite?) quadrants every conjugation is generated in.
    QUADRANTS = [ [ false, false ], [ false, true ], [ true, false ], [ true, true ] ].freeze

    # JMdict codes whose full paradigm lives directly in conjo.csv, mapped to a
    # coarse kind for grouping. Archaic classes (v2*, v4*) and bare nouns are
    # deliberately absent — they simply aren't offered for conjugation.
    DIRECT = {
      "adj-i" => :i_adjective, "adj-ix" => :i_adjective,
      "v1" => :ichidan, "v1-s" => :ichidan,
      "v5aru" => :godan, "v5b" => :godan, "v5g" => :godan, "v5k" => :godan,
      "v5k-s" => :godan, "v5m" => :godan, "v5n" => :godan, "v5r" => :godan,
      "v5r-i" => :godan, "v5s" => :godan, "v5t" => :godan, "v5u" => :godan,
      "v5u-s" => :godan,
      "vk" => :kuru, "vs-i" => :suru, "vs-s" => :suru
    }.freeze

    COPULA_POS = 15  # the copula だ — na-adjectives conjugate through it
    SURU_POS   = 48  # vs-i (する) — `vs` nouns conjugate by appending する

    class << self
      # True if any of `pos` (a JMdict code or array of codes) can be conjugated.
      def conjugatable?(pos)
        Array(pos).any? { |code| strategy(code.to_s) }
      end

      # Conjugate `kanji`/`reading` (dictionary forms) according to `pos`. When
      # `pos` is an array the first conjugatable code wins. Returns a Result, or
      # nil when nothing is conjugatable.
      def conjugate(kanji:, reading:, pos:)
        code = Array(pos).map(&:to_s).find { |c| strategy(c) }
        return nil unless code

        strat   = strategy(code)
        kanji   = nil if kanji.to_s.empty?
        reading = reading.to_s
        return nil if kanji.nil? && reading.empty?

        forms = build(strat, kanji, reading)
        forms.empty? ? nil : Result.new(pos: code, kind: strat[:kind], forms: forms)
      end

      private

      # Walk every (conjugation, quadrant, onum) row defined for this pos and
      # construct the inflected kanji + reading.
      def build(strat, kanji, reading)
        if strat[:append]
          kanji = (kanji || reading) + strat[:append]
          reading += strat[:append]
        end

        Tables.conj.keys.sort.flat_map do |conj_id|
          QUADRANTS.flat_map do |negative, polite|
            (1..9).filter_map do |onum|
              row = Tables.conjo[[ strat[:pos_id], conj_id, negative, polite, onum ]]
              next unless row

              kf = inflect(strat, kanji, row)
              rf = inflect(strat, reading, row)
              next if kf.nil? && rf.nil?

              Form.new(conjugation: conj_id, name: Tables.conj[conj_id],
                       negative: negative, polite: polite, onum: onum,
                       kanji: kf, reading: rf)
            end
          end
        end
      end

      def inflect(strat, text, row)
        return nil if text.nil? || text.empty?

        if strat[:suffix]
          # Copula forms are whole suffixes appended to the citation form
          # (静か → 静かだ / 静かではない); no stem stripping or euphony.
          text + row.okuri.to_s
        else
          construct(text, row.stem, row.okuri, row.euphr, row.euphk)
        end
      end

      # Port of jconj `construct()`: drop `stem` trailing characters (plus one
      # more when a euphonic change applies to this script), then append the
      # euphonic stem char and the okurigana. Whether `text` is treated as kana
      # (euphr) or kanji (euphk) is decided by its next-to-last character — the
      # one that actually inflects.
      def construct(text, stem, okuri, euphr, euphk)
        return nil if text.length < 2

        kana = text[-2] > "あ" && text[-2] <= "ん"
        euph = kana ? euphr : euphk
        stem += 1 if euph
        cut = text.length - stem
        return nil if cut.negative?

        text[0, cut] + (euph || "") + okuri.to_s
      end

      # JMdict code => { pos_id:, kind:, [suffix:|append:] }, or nil.
      def strategy(code)
        if (kind = DIRECT[code])
          { pos_id: Tables.pos_ids.fetch(code), kind: kind }
        elsif code == "adj-na"
          { pos_id: COPULA_POS, kind: :na_adjective, suffix: true }
        elsif code == "vs"
          { pos_id: SURU_POS, kind: :suru, append: "する" }
        end
      end
    end
  end
end
