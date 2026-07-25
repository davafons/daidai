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
    # pos-id renumber upstream can't silently misapply the fix; values override
    # only the given Okurigana fields.
    #
    #   • v5u negative conditional (買う → 買わなかったら): upstream conjo.csv stores
    #     "わかったら", dropping the な. Every other class is correct here (v5u-s
    #     even has わなかったら), so this one cell is a typo. Without it every
    #     godan-u verb's negative ~tara comes out as 買わかったら / 使わかったら / ….
    CONJO_ERRATA = {
      [ "v5u", 11, true, false, 1 ] => { okuri: "わなかったら" }
    }.freeze

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

      # Overlay CONJO_ERRATA onto the freshly-loaded table, resolving each JMdict
      # code to its pos id. A correction that no longer matches a row (upstream
      # fixed it, or restructured) is skipped silently — the errata is advisory.
      def apply_conjo_errata(table)
        CONJO_ERRATA.each do |(code, conj, neg, fml, onum), fix|
          pos_id = pos_ids[code] or next
          key = [ pos_id, conj, neg, fml, onum ]
          row = table[key] or next
          table[key] = Okurigana.new(
            stem: fix.fetch(:stem, row.stem),
            okuri: fix.fetch(:okuri, row.okuri),
            euphr: fix.fetch(:euphr, row.euphr),
            euphk: fix.fetch(:euphk, row.euphk)
          )
        end
        table
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
