# frozen_string_literal: true

module Daidai
  # One conjugated form. `kanji`/`reading` hold the inflected surface and its
  # kana (either may be nil when the word has no kanji writing). `onum`
  # disambiguates forms with several accepted variants (e.g. ～なくて vs ～ないで).
  Form = Struct.new(:conjugation, :name, :negative, :polite, :onum, :kanji, :reading, keyword_init: true) do
    def negative? = negative
    def polite?   = polite
    def primary?  = onum == 1

    # The form to show: kanji writing when present, otherwise the kana.
    def text = kanji || reading
  end

  # The full paradigm for one word. `forms` is every generated Form; the
  # helpers below pull out the slices a UI usually wants.
  Result = Struct.new(:pos, :kind, :forms, keyword_init: true) do
    # Forms for one conjugation id, primary variant only, keyed for a grid:
    # { [negative, polite] => Form }.
    def grid(conjugation)
      forms.select { |f| f.conjugation == conjugation && f.primary? }
           .to_h { |f| [ [ f.negative, f.polite ], f ] }
    end

    # Conjugation ids present, in table order.
    def conjugations
      forms.map(&:conjugation).uniq
    end

    def name(conjugation)
      forms.find { |f| f.conjugation == conjugation }&.name
    end
  end
end
