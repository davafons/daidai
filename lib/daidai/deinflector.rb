# frozen_string_literal: true

require "json"

module Daidai
  # A single deinflection candidate: a base-form `term` reached from the input by
  # applying `inflections` (transform names, ordered from the surface form inward
  # to the dictionary form). `dictionary_form?` is true when the rule chain lands
  # on a recognised dictionary form (a likely real lemma), useful for callers
  # without their own dictionary to look the term up in.
  #
  #   Daidai.deinflect("食べてる")   # candidate base forms, each with named inflections;
  #                                  # one is #<Daidai::Deinflection 食べる [-いる, -て]>
  Deinflection = Struct.new(:term, :inflections, :dictionary_form, keyword_init: true) do
    def dictionary_form? = dictionary_form

    # The inflections as friendly English labels for display (e.g. "-いる" =>
    # "progressive", "-て" => "te-form"), via Deinflector.label. Localise these
    # downstream (i18n) if your app is multilingual.
    def labels = inflections.map { |name| Deinflector.label(name) }

    def to_s = inflections.empty? ? term : "#{term} [#{inflections.join(", ")}]"

    def inspect = "#<Daidai::Deinflection #{self}>"
  end

  # Rule-based Japanese deinflector: turns an inflected surface form back into its
  # dictionary form(s), naming each inflection along the way ("食べてる" is the
  # progressive of "食べる"). This is the inverse of Daidai's forward conjugation.
  #
  # The rule set is ported from Yomitan's Japanese language transforms
  # (ext/js/language/ja/japanese-transforms.js), vendored as JSON under
  # resources/; the algorithm is a port of Yomitan's LanguageTransformer. Both are
  # GPL-3.0 — see NOTICE. Unlike Daidai's forward tables, these rules also cover
  # colloquial contractions (てる, ちゃう, とく, …).
  #
  # Unlike `Daidai.conjugate(word)`, this needs no Sudachi/kabosu — it is pure,
  # offline, string-rule deinflection.
  module Deinflector
    DATA_FILE = File.expand_path("resources/japanese-transforms.json", __dir__)

    # Friendly English labels for the deinflection rule names #deinflect emits.
    # The underlying names (ported from Yomitan) are terse and sometimes symbolic
    # ("-いる", "-て", "-ます"); these name the grammar instead ("progressive",
    # "te-form", "polite"). This is daidai's curation, not Yomitan data — it is
    # the single source of truth for naming an inflection, so consumers localise
    # these rather than maintain their own map. Keyed by the rule name; see
    # Deinflector.label for the lookup (which falls back to the name itself).
    LABELS = {
      "-いる" => "progressive", "-て" => "te-form", "-た" => "past",
      "-ます" => "polite", "negative" => "negative", "passive" => "passive",
      "potential" => "potential", "potential or passive" => "potential / passive",
      "causative" => "causative", "short causative" => "short causative",
      "volitional" => "volitional", "volitional slang" => "volitional (slang)",
      "imperative" => "imperative", "continuative" => "continuative",
      "-たい" => "desiderative (-tai)", "-たら" => "conditional (-tara)",
      "-たり" => "representative (-tari)", "-ば" => "provisional (-ba)",
      "-ゃ" => "conditional contraction (-ya)", "-ちゃ" => "contracted (-cha)",
      "-ちゃう" => "completive (-chau)", "-ちまう" => "completive (-chimau)",
      "-しまう" => "completive (-shimau)", "-おく" => "preparatory (-oku)",
      "-そう" => "looks like (-sou)", "-すぎる" => "excessive (-sugiru)",
      "-過ぎる" => "excessive (-sugiru)", "-なさい" => "polite imperative (-nasai)",
      "-さ" => "nominalization (-sa)", "-げ" => "appearance (-ge)",
      "-がる" => "showing signs (-garu)", "-やがる" => "contemptuous (-yagaru)",
      "-ず" => "negative (-zu)", "-ぬ" => "negative (-nu)", "-ん" => "negative (-n)",
      "-ざる" => "negative (-zaru)", "-ねば" => "negative conditional (-neba)",
      "-まい" => "negative volitional (-mai)", "-く" => "adverbial (-ku)",
      "-き" => "attributive (-ki)", "-む" => "archaic volitional (-mu)",
      "-んばかり" => "on the verge (-nbakari)", "-んとする" => "intentive (-ntosuru)",
      "-え" => "slang (-e)", "n-slang" => "n-slang",
      "imperative negative slang" => "imperative negative (slang)",
      "kansai-ben" => "kansai dialect"
    }.freeze

    # One deinflection rule: a test for the inflected form and how to undo it.
    Rule = Struct.new(:is_inflected, :deinflect, :conditions_in, :conditions_out, keyword_init: true)

    # A named group of rules (one grammatical transformation, e.g. "negative").
    Transform = Struct.new(:id, :name, :rules, :heuristic, keyword_init: true)

    # An intermediate (or final) deinflected form during the search.
    TransformedText = Struct.new(:text, :conditions, :trace, keyword_init: true)

    class << self
      # Every deinflection candidate for `text`, faithful to the transformer: each
      # term the rules can reach, with its named inflection chain. Excludes the
      # trivial zero-transform identity. Callers with a dictionary look up each
      # `term`; callers without one can keep only `dictionary_form?` candidates.
      def deinflect(text)
        transform(text)
          .reject { |t| t.trace.empty? }
          .map { |t| to_deinflection(t) }
          .uniq { |d| [ d.term, d.inflections ] }
      end

      # Friendly English label for a deinflection rule name (the strings in a
      # Deinflection's #inflections), e.g. "-いる" => "progressive". Falls back to
      # the name itself for anything not in LABELS, so it is always safe to call.
      def label(name)
        LABELS.fetch(name.to_s, name.to_s)
      end

      # The raw transformer output (a TransformedText per reachable form, including
      # the identity). Mirrors Yomitan's LanguageTransformer#transform.
      def transform(source_text)
        results = [ TransformedText.new(text: source_text, conditions: 0, trace: []) ]
        i = 0
        while i < results.length
          current = results[i]
          transforms.each do |transform|
            next unless transform.heuristic.match?(current.text)

            transform.rules.each_with_index do |rule, j|
              next unless conditions_match?(current.conditions, rule.conditions_in)
              next unless rule.is_inflected.match?(current.text)
              next if cycle?(current.trace, transform.id, j, current.text)

              results << TransformedText.new(
                text: rule.deinflect.call(current.text),
                conditions: rule.conditions_out,
                trace: [ { transform: transform.id, rule_index: j, text: current.text } ] + current.trace
              )
            end
          end
          i += 1
        end
        results
      end

      def reload!
        @data = @condition_flags = @dictionary_mask = @transforms = @transforms_by_id = nil
      end

      private

      def to_deinflection(transformed)
        Deinflection.new(
          term: transformed.text,
          # trace is newest-first (innermost rule first); reverse so the names read
          # from the surface form inward to the dictionary form.
          inflections: transformed.trace.reverse.map { |frame| transforms_by_id[frame[:transform]].name },
          dictionary_form: transformed.conditions.anybits?(dictionary_mask)
        )
      end

      def conditions_match?(current, following)
        current.zero? || current.anybits?(following)
      end

      def cycle?(trace, transform_id, rule_index, text)
        trace.any? { |f| f[:transform] == transform_id && f[:rule_index] == rule_index && f[:text] == text }
      end

      def data
        @data ||= JSON.parse(File.read(DATA_FILE))
      end

      def transforms
        @transforms ||= build_transforms
      end

      def transforms_by_id
        @transforms_by_id ||= transforms.to_h { |t| [ t.id, t ] }
      end

      def build_transforms
        flags = condition_flags
        data["transforms"].map do |id, t|
          rules = t["rules"].map { |r| build_rule(r, flags) }
          heuristic = Regexp.new(rules.map { |r| r.is_inflected.source }.join("|"))
          Transform.new(id: id, name: t["name"], rules: rules, heuristic: heuristic)
        end
      end

      # Build a rule's matcher + undo closure. The inflected/deinflected fragments
      # are literal kana/kanji (no regex metacharacters), matched verbatim as in
      # Yomitan's helpers.
      def build_rule(rule, flags)
        inflected, deinflected = rule.values_at("inflected", "deinflected")
        is_inflected, deinflect =
          case rule["type"]
          when "suffix"
            [ /#{inflected}$/, ->(text) { text[0...(text.length - inflected.length)] + deinflected } ]
          when "wholeWord"
            [ /\A#{inflected}\z/, ->(_text) { deinflected } ]
          when "prefix"
            [ /\A#{inflected}/, ->(text) { deinflected + text[inflected.length..] } ]
          else
            raise Error, "Unknown deinflection rule type: #{rule["type"]}"
          end
        Rule.new(
          is_inflected: is_inflected,
          deinflect: deinflect,
          conditions_in: strict_flags(flags, rule["conditionsIn"]),
          conditions_out: strict_flags(flags, rule["conditionsOut"])
        )
      end

      # Bitmask of every dictionary-form condition, for tagging terminal lemmas.
      def dictionary_mask
        @dictionary_mask ||= data["conditions"].sum do |type, c|
          c["isDictionaryForm"] ? condition_flags[type] : 0
        end
      end

      # Assign each leaf condition a distinct bit; a condition with subConditions
      # gets the OR of theirs. Resolved iteratively since a parent may precede its
      # children (a port of LanguageTransformer#_getConditionFlagsMap).
      def condition_flags
        @condition_flags ||= compute_condition_flags
      end

      def compute_condition_flags
        conditions = data["conditions"]
        flags = {}
        next_index = 0
        targets = conditions.keys
        until targets.empty?
          remaining = []
          targets.each do |type|
            sub = conditions[type]["subConditions"]
            if sub.nil?
              raise Error, "Too many deinflection conditions (max 32)" if next_index >= 32

              flags[type] = 1 << next_index
              next_index += 1
            else
              resolved = strict_flags(flags, sub) { remaining << type }
              flags[type] = resolved if resolved
            end
          end
          raise Error, "Cycle in deinflection sub-conditions" if remaining.size == targets.size

          targets = remaining
        end
        flags
      end

      # OR the flags of every named condition. Yields (and returns nil) when one
      # isn't assigned yet, so condition resolution can defer it to a later pass.
      def strict_flags(flags, types)
        result = 0
        types.each do |type|
          flag = flags[type]
          if flag.nil?
            yield if block_given?
            return nil
          end
          result |= flag
        end
        result
      end
    end
  end
end
