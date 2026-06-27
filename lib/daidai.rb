# frozen_string_literal: true

require_relative "daidai/version"
require_relative "daidai/conjugator"
require_relative "daidai/kabosu"

# Daidai (橙) — Japanese verb and adjective conjugation in pure Ruby.
#
# The conjugation knowledge comes from the JMdictDB tables developed by Jim
# Breen's EDRDG project (via jconj); Daidai ports the table-driven algorithm and
# exposes a small, app-friendly API. Named after the bitter orange, a sibling of
# sudachi and kabosu.
#
#   Daidai.conjugate(kanji: "書く", reading: "かく", pos: "v5k")
#   #=> Daidai::Result
#
#   Daidai.conjugatable?("n")   #=> false
#   Daidai.conjugatable?("v1")  #=> true
module Daidai
  class << self
    # Conjugate a dictionary-form word.
    #
    #   Daidai.conjugate("書く", "v5k")                 # kanji surface forms
    #   Daidai.conjugate("書く", "v5k", reading: "かく")  # + the kana of each form
    #   Daidai.conjugate("する", "vs-i")                # kana word (is its own reading)
    #
    # `word` is the dictionary form (kanji surface or kana). `pos` is a JMdict
    # part-of-speech code ("v5k", "adj-i", …) or an array of them — the first
    # conjugatable one wins. `reading` is optional: pass it only when you also
    # want each form's kana (conjugation rewrites the okurigana, which is already
    # in the surface, so the kanji forms need no reading). Returns a Daidai::Word,
    # or nil when nothing is conjugatable.
    #
    # `pos` may be omitted, in which case the optional `kabosu` gem (Sudachi)
    # resolves the dictionary form, POS and reading from `word` — even when `word`
    # is itself inflected ("食べている" → conjugations of 食べる). This raises
    # Daidai::Kabosu::MissingDependency if kabosu/a dictionary isn't installed.
    def conjugate(word, pos = nil, reading: nil)
      return nil if word.nil? || word.to_s.empty?

      if pos.nil?
        resolved = Kabosu.resolve(word) or return nil
        word, pos, reading = resolved.values_at(:word, :pos, :reading)
      end

      kanji = word.match?(/\p{Han}/) ? word : nil
      reading ||= kanji ? nil : word
      Conjugator.conjugate(kanji: kanji, reading: reading, pos: pos)
    end

    # Whether `pos` (a code or array of codes) describes a conjugatable word.
    def conjugatable?(pos)
      Conjugator.conjugatable?(pos)
    end
  end
end
