# frozen_string_literal: true

module Daidai
  # The conjugation forms daidai generates, in table order, with display labels.
  # These names replace the numeric conjugation ids of the underlying tables.
  FORMS = {
    non_past: "Non-past",
    past: "Past",
    te: "Te-form",
    provisional: "Provisional (~eba)",
    potential: "Potential",
    passive: "Passive",
    causative: "Causative",
    causative_passive: "Causative-passive",
    volitional: "Volitional",
    imperative: "Imperative",
    conditional: "Conditional (~tara)",
    alternative: "Alternative (~tari)",
    stem: "Continuative (~i)"
  }.freeze

  # conjo.csv conjugation id (1..13) => form name, in the same order as FORMS.
  FORM_BY_ID = FORMS.keys.each_with_index.to_h { |name, i| [ i + 1, name ] }.freeze

  # A single conjugated form. `kanji` and `reading` hold the inflected surface
  # and its kana; either may be nil (a kana-only word has no `kanji`, and the
  # `reading` is only filled in when one was supplied). `onum` distinguishes
  # equally-valid variants of the same form (e.g. ～なくて vs ～ないで).
  Form = Struct.new(:name, :negative, :polite, :onum, :kanji, :reading, keyword_init: true) do
    def negative? = negative
    def polite?   = polite

    # The primary (most standard) variant for its form/polarity/formality; see
    # Word#variants for the alternatives (e.g. ～なくて beside ～ないで).
    def primary? = onum == 1

    # Human label for this form ("Past", "Te-form", …).
    def label = FORMS[name]

    # The text to show: the kanji writing if there is one, otherwise the kana.
    def to_s = (kanji || reading).to_s
    alias_method :text, :to_s

    def inspect = "#<Daidai::Form #{name}#{" negative" if negative}#{" polite" if polite}: #{self}>"
  end

  # A conjugated word — the full paradigm for one dictionary-form input.
  #
  # Forms are reached by name, with optional negative:/polite: modifiers:
  #
  #   word.past                      #=> Form  (plain affirmative)
  #   word.past(polite: true)        #=> Form
  #   word.non_past(negative: true)  #=> Form
  #
  # …or through fluent views that read like grammar (and chain):
  #
  #   word.polite.past
  #   word.negative.non_past
  #   word.polite.negative.te
  #
  # `word[:past, polite: true]` does the same dynamically, and a Word is
  # Enumerable over all of its forms.
  class Word
    include Enumerable

    attr_reader :word, :pos, :kind, :forms

    def initialize(word:, pos:, kind:, forms:)
      @word  = word
      @pos   = pos
      @kind  = kind
      @forms = forms
      @index = forms.group_by { |f| [ f.name, f.negative, f.polite ] }
    end

    # The primary Form for `name` in the given polarity/formality, or nil.
    def [](name, negative: false, polite: false)
      @index[[ name, negative, polite ]]&.min_by(&:onum)
    end
    alias form []

    # Every accepted variant (all onums) for a form, primary first.
    def variants(name, negative: false, polite: false)
      (@index[[ name, negative, polite ]] || []).sort_by(&:onum)
    end

    def each(&) = @forms.each(&)

    # The form names present for this word, in table order.
    def conjugations
      present = @forms.map(&:name).uniq
      FORMS.keys.select { |name| present.include?(name) }
    end

    # Fluent views — a lens with polarity/formality pre-applied.
    def polite      = View.new(self, negative: false, polite: true)
    def plain       = View.new(self, negative: false, polite: false)
    def negative    = View.new(self, negative: true, polite: false)
    def affirmative = View.new(self, negative: false, polite: false)

    FORMS.each_key do |name|
      define_method(name) do |negative: false, polite: false|
        self[name, negative: negative, polite: polite]
      end
    end

    alias dictionary non_past
    alias te_form te

    def inspect = "#<Daidai::Word #{word} (#{pos}, #{kind}): #{@forms.size} forms>"
  end

  # A polarity/formality lens over a Word, returned by Word#polite etc. Calling
  # a form name on it applies the accumulated modifiers; modifiers chain.
  class View
    def initialize(word, negative:, polite:)
      @word     = word
      @negative = negative
      @polite   = polite
    end

    def polite      = View.new(@word, negative: @negative, polite: true)
    def plain       = View.new(@word, negative: @negative, polite: false)
    def negative    = View.new(@word, negative: true, polite: @polite)
    def affirmative = View.new(@word, negative: false, polite: @polite)

    FORMS.each_key do |name|
      define_method(name) { @word[name, negative: @negative, polite: @polite] }
    end

    alias dictionary non_past
    alias te_form te
  end
end
