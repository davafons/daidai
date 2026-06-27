# frozen_string_literal: true

module Daidai
  class Error < StandardError; end

  # Optional Sudachi-backed resolver. Turns a bare word — even an inflected one
  # like "食べている" — into its dictionary form and JMdict part of speech, so you
  # can conjugate without naming the POS yourself:
  #
  #   Daidai.conjugate("食べている")   # Sudachi finds 食べる / v1, then conjugates
  #
  # This needs the `kabosu` gem (Sudachi bindings) plus an installed Sudachi
  # dictionary. Neither is a hard dependency of daidai — the rest of the gem is
  # pure Ruby and zero-dependency. The escape hatch is simply to pass the POS, in
  # which case Sudachi never runs:
  #
  #   Daidai.conjugate("食べる", "v1")
  module Sudachi
    # Raised when a POS-less conjugation is requested but Sudachi (the `kabosu`
    # gem and a dictionary) isn't available.
    class MissingDependency < Error; end

    # Sudachi 活用型 (conjugation type) => JMdict POS code. Sudachi names the verb
    # row but not the JMdict subclass for a handful of irregulars, so LEMMA_POS
    # overrides those by dictionary form.
    CONJUGATION_TYPE = {
      "五段-カ行" => "v5k", "五段-ガ行" => "v5g", "五段-サ行" => "v5s",
      "五段-タ行" => "v5t", "五段-ナ行" => "v5n", "五段-バ行" => "v5b",
      "五段-マ行" => "v5m", "五段-ラ行" => "v5r", "五段-ワア行" => "v5u",
      "カ行変格" => "vk", "サ行変格" => "vs-i"
    }.freeze

    # Dictionary-form overrides for verbs whose JMdict subclass Sudachi's 活用型
    # can't distinguish (irregular okurigana inside an otherwise-regular row).
    LEMMA_POS = {
      "行く" => "v5k-s", "逝く" => "v5k-s", "往く" => "v5k-s",
      "有る" => "v5r-i", "在る" => "v5r-i", "ある" => "v5r-i"
    }.freeze

    class << self
      # Resolve `text` to { word:, pos:, reading: } from its first inflecting
      # morpheme, or nil when nothing conjugatable is found. Raises
      # MissingDependency when Sudachi isn't installed.
      def resolve(text)
        morphemes = tokenizer.tokenize(text).to_a
        index = morphemes.index { |m| inflecting?(m.part_of_speech) }
        return nil unless index

        morpheme = morphemes[index]
        preceding = index.positive? ? morphemes[index - 1] : nil

        # 名詞+する compounds (勉強した → 勉強, vs): the noun is the dictionary entry.
        if suru?(morpheme.part_of_speech) && preceding && suru_noun?(preceding.part_of_speech)
          return entry(preceding, "vs")
        end

        pos = jmdict_pos(morpheme.part_of_speech, morpheme.dictionary_form)
        pos && entry(morpheme, pos)
      end

      # Pure mapping: a Sudachi part-of-speech array + dictionary form => JMdict
      # POS code, or nil. Exposed (and unit-tested) without needing kabosu.
      def jmdict_pos(pos, lemma)
        LEMMA_POS[lemma] || from_conjugation_type(pos)
      end

      # Whether the Sudachi path is usable (kabosu loadable + a dictionary present).
      def available?
        !tokenizer.nil?
      rescue MissingDependency
        false
      end

      def reset! = (@tokenizer = nil)

      private

      def from_conjugation_type(pos)
        case pos[0]
        when "動詞"
          CONJUGATION_TYPE[pos[4]] || (pos[4].to_s.start_with?("上一段", "下一段") ? "v1" : nil)
        when "形容詞" then "adj-i"
        when "形状詞" then "adj-na"
        end
      end

      def inflecting?(pos)
        %w[動詞 形容詞 形状詞].include?(pos[0])
      end

      def suru?(pos) = pos[4] == "サ行変格"
      def suru_noun?(pos) = pos[0] == "名詞" && pos[2] == "サ変可能"

      def entry(morpheme, pos)
        { word: morpheme.dictionary_form, pos: pos, reading: dictionary_reading(morpheme) }
      end

      # `reading_form` is the *surface* reading; it matches the dictionary form
      # only when the input wasn't inflected. Otherwise leave the reading to
      # conjugate — a kana word is its own reading, and a kanji word just omits
      # the kana column rather than carry a wrong one.
      def dictionary_reading(morpheme)
        return nil unless morpheme.surface == morpheme.dictionary_form

        hiragana(morpheme.reading_form)
      end

      def tokenizer
        @tokenizer ||= build_tokenizer
      end

      def build_tokenizer
        require "kabosu"
        Kabosu::Dictionary.new(system_dict: Kabosu::Dictionary.path).create(mode: :c)
      rescue LoadError
        raise MissingDependency,
              'Daidai.conjugate(word) without a POS needs the `kabosu` gem. Add `gem "kabosu"` ' \
              '(and install a Sudachi dictionary), or pass the JMdict POS: Daidai.conjugate(word, "v5k").'
      rescue StandardError => e
        raise MissingDependency,
              "Sudachi is unavailable (#{e.message}). Install a dictionary (e.g. `rake kabosu:install`), " \
              'or pass the JMdict POS explicitly: Daidai.conjugate(word, "v5k").'
      end

      def hiragana(text)
        text.to_s.tr("ァ-ヴ", "ぁ-ゔ")
      end
    end
  end
end
