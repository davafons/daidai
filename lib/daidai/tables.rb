# frozen_string_literal: true

require "csv"

module Daidai
  # Loads and memoizes the JMdictDB conjugation tables vendored under
  # `resources/`. The files are tab-separated and copied verbatim from jconj
  # (Stuart McGraw / EDRDG) — see NOTICE. Keep them in sync with upstream via
  # `rake daidai:sync`.
  module Tables
    DIR = File.expand_path("resources", __dir__)

    # One okurigana rule: how to turn a dictionary form into one conjugation.
    Okurigana = Struct.new(:stem, :okuri, :euphr, :euphk, keyword_init: true)

    # Corrections for known errors in the upstream JMdictDB tables, applied at
    # load so the vendored CSVs stay byte-identical to upstream (keeping
    # `rake daidai:check_resources` green) while daidai still emits the right
    # form. Keyed by JMdict code + [conj_id, negative?, polite?, onum] so a
    # pos-id renumber upstream can't silently misapply the fix; each value is
    # the whole row as it should read, added when upstream has none.
    #
    #   • v5u negative conditional (買う → 買わなかったら): upstream conjo.csv stores
    #     "わかったら", dropping the な. Every other class is correct here (v5u-s
    #     even has わなかったら), so this one cell is a typo. Without it every
    #     godan-u verb's negative ~tara comes out as 買わかったら / 使わかったら / ….
    #   • vs-s negatives: upstream gives only the godan negative (愛さない), which
    #     is wrong for 察する, 達する, 反する and 有する (察しない). The サ変 one
    #     is added beside it, and the te-form pairs なくて with ないで in each.
    CONJO_ERRATA = {
      [ "v5u", 11, true, false, 1 ] => { stem: 1, okuri: "わなかったら" },
      [ "vs-s", 1, true, false, 2 ] => { stem: 1, okuri: "ない", euphr: "し" },
      [ "vs-s", 2, true, false, 2 ] => { stem: 1, okuri: "なかった", euphr: "し" },
      [ "vs-s", 3, true, false, 2 ] => { stem: 1, okuri: "ないで", euphr: "さ" },
      [ "vs-s", 3, true, false, 3 ] => { stem: 1, okuri: "なくて", euphr: "し" },
      [ "vs-s", 3, true, false, 4 ] => { stem: 1, okuri: "ないで", euphr: "し" },
      [ "vs-s", 4, true, false, 2 ] => { stem: 1, okuri: "なければ", euphr: "し" },
      [ "vs-s", 11, true, false, 2 ] => { stem: 1, okuri: "なかったら", euphr: "し" },
      [ "vs-s", 12, true, false, 2 ] => { stem: 1, okuri: "なかったり", euphr: "し" }
    }.freeze

    # Upstream rows that are no form of the class, as JMdict code + [conj_id,
    # onum]. Each goes in every polarity and formality.
    #
    #   • ある has no potential (国際交流基金 lists it among the verbs without
    #     one): あれる is 荒れる. Its short causative あらす is 荒らす, and
    #     あらされる is 荒らされる.
    CONJO_REMOVED = [
      [ "v5r-i", 5, 1 ], [ "v5r-i", 7, 2 ], [ "v5r-i", 8, 2 ]
    ].freeze

    class << self
      # conjugation id (Integer) => human name ("Past (~ta)", …)
      def conj
        @conj ||= read("conj.csv").to_h { |r| [ r["id"].to_i, r["name"] ] }
      end

      # [pos_id, conj_id, negative?, polite?, onum] => Okurigana
      def conjo
        @conjo ||= begin
          table = read("conjo.csv").each_with_object({}) do |r, acc|
            key = [ r["pos"].to_i, r["conj"].to_i, r["neg"] == "t", r["fml"] == "t", r["onum"].to_i ]
            acc[key] = Okurigana.new(
              stem: r["stem"].to_i,
              okuri: r["okuri"].to_s,
              euphr: presence(r["euphr"]),
              euphk: presence(r["euphk"])
            )
          end
          apply_conjo_errata(table)
        end
      end

      # JMdict POS keyword ("v5k", "adj-i", …) => conjo pos id (Integer)
      def pos_ids
        @pos_ids ||= read("kwpos.csv").to_h { |r| [ r["kw"], r["id"].to_i ] }
      end

      def reload!
        @conj = @conjo = @pos_ids = nil
      end

      private

      # Overlay CONJO_ERRATA and CONJO_REMOVED onto the freshly-loaded table,
      # resolving each JMdict code to its pos id.
      def apply_conjo_errata(table)
        CONJO_ERRATA.each do |(code, conj, neg, fml, onum), row|
          pos_id = pos_ids[code] or next
          table[[ pos_id, conj, neg, fml, onum ]] = Okurigana.new(**row)
        end
        removed = CONJO_REMOVED.filter_map { |code, conj, onum| [ pos_ids[code], conj, onum ] if pos_ids[code] }
        table.reject { |(pos_id, conj, _neg, _fml, onum), _row| removed.include?([ pos_id, conj, onum ]) }
      end

      def read(file, headers: true)
        CSV.read(File.join(DIR, file), col_sep: "\t", headers: headers, quote_char: '"')
      end

      def presence(value)
        value.nil? || value.empty? ? nil : value
      end
    end
  end
end
