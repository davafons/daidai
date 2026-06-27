# frozen_string_literal: true

require_relative "daidai/version"
require_relative "daidai/conjugator"

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
    # Conjugate a dictionary-form word. `pos` is a JMdict part-of-speech code
    # (e.g. "v5k", "adj-i") or an array of them — the first conjugatable wins.
    # Returns a Daidai::Result, or nil when nothing is conjugatable.
    def conjugate(pos:, kanji: nil, reading: nil)
      Conjugator.conjugate(kanji: kanji, reading: reading, pos: pos)
    end

    # Whether `pos` (a code or array of codes) describes a conjugatable word.
    def conjugatable?(pos)
      Conjugator.conjugatable?(pos)
    end
  end
end
