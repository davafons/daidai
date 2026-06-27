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

    class << self
      # conjugation id (Integer) => human name ("Past (~ta)", …)
      def conj
        @conj ||= read("conj.csv").to_h { |r| [ r["id"].to_i, r["name"] ] }
      end

      # [pos_id, conj_id, negative?, polite?, onum] => Okurigana
      def conjo
        @conjo ||= read("conjo.csv").each_with_object({}) do |r, table|
          key = [ r["pos"].to_i, r["conj"].to_i, r["neg"] == "t", r["fml"] == "t", r["onum"].to_i ]
          table[key] = Okurigana.new(
            stem: r["stem"].to_i,
            okuri: r["okuri"].to_s,
            euphr: presence(r["euphr"]),
            euphk: presence(r["euphk"])
          )
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

      def read(file, headers: true)
        CSV.read(File.join(DIR, file), col_sep: "\t", headers: headers, quote_char: '"')
      end

      def presence(value)
        value.nil? || value.empty? ? nil : value
      end
    end
  end
end
