# frozen_string_literal: true

require_relative "test_helper"

# The rule-based deinflector (ported from Yomitan). It is dictionary-free, so it
# returns every candidate the rules can reach — these tests assert that the
# *expected* base form appears with the right named inflection chain, not that it
# is the only candidate.
class DeinflectorTest < Minitest::Test
  # The inflection chain (surface -> dictionary) for `lemma` among the candidates
  # of `surface`, or nil when the deinflector never reaches `lemma`.
  def chain(surface, lemma)
    Daidai.deinflect(surface).find { |d| d.term == lemma }&.inflections
  end

  def test_progressive_contraction
    assert_equal %w[-いる -て], chain("食べてる", "食べる")
  end

  def test_progressive_full
    assert_equal %w[-いる -て], chain("食べている", "食べる")
  end

  def test_negative_past
    assert_equal %w[-た negative], chain("読まなかった", "読む")
  end

  def test_negative_conditional
    assert_equal %w[-ば negative], chain("飲まなければ", "飲む")
  end

  def test_adjective_negative
    assert_equal %w[negative], chain("高くない", "高い")
  end

  def test_causative_passive_past
    assert_equal [ "-た", "potential or passive", "causative" ], chain("食べさせられた", "食べる")
  end

  def test_shimau_contraction
    assert_equal %w[-ちゃう], chain("食べちゃう", "食べる")
  end

  def test_kuru_past
    assert_equal %w[-た], chain("来た", "来る")
  end

  def test_polite_past
    assert_equal %w[-た -ます], chain("食べました", "食べる")
  end

  def test_dictionary_form_flag
    found = Daidai.deinflect("食べてる").find { |d| d.term == "食べる" }

    assert found.dictionary_form?, "食べる should be flagged as a dictionary form"
  end

  def test_excludes_identity_and_dedupes
    results = Daidai.deinflect("読まなかった")

    refute(results.any? { |d| d.inflections.empty? }, "must not return the zero-transform identity")
    assert_equal results.size, results.uniq { |d| [ d.term, d.inflections ] }.size
  end

  def test_blank_input
    assert_empty Daidai.deinflect("")
    assert_empty Daidai.deinflect(nil)
  end

  def test_labels_name_the_grammar
    d = Daidai.deinflect("食べてる").find { |x| x.term == "食べる" }

    assert_equal %w[-いる -て], d.inflections
    assert_equal %w[progressive te-form], d.labels
  end

  def test_label_falls_back_to_the_name
    assert_equal "progressive", Daidai::Deinflector.label("-いる")
    assert_equal "negative", Daidai::Deinflector.label("negative")
    assert_equal "future-rule", Daidai::Deinflector.label("future-rule")
  end

  def test_every_emitted_rule_name_has_a_curated_label
    names = Daidai::Deinflector.send(:data)["transforms"].values.map { |t| t["name"] }.uniq
    uncurated = names.reject { |name| Daidai::Deinflector::LABELS.key?(name) }

    assert_empty uncurated, "rule names without a curated label: #{uncurated.inspect}"
  end

  def test_deinflection_to_s
    found = Daidai.deinflect("食べてる").find { |d| d.term == "食べる" }

    assert_equal "食べる [-いる, -て]", found.to_s
  end

  # Round-trip: the common plain forms Daidai conjugates should deinflect back to
  # the dictionary word. (jconj over-generates some unusual polite combinations
  # and picks variants — ～ないで, prohibitive ～な — that Yomitan's deinflector
  # intentionally doesn't cover, so the property only holds for the core forms.)
  def test_round_trip_plain_forms
    cases = { "食べる" => "v1", "書く" => "v5k", "飲む" => "v5m" }
    cases.each do |word, pos|
      Daidai.conjugate(word, pos).forms.each do |form|
        next if form.polite? || form.text == word
        next if form.negative? && %i[te imperative].include?(form.name)

        terms = Daidai.deinflect(form.text).map(&:term)
        assert_includes terms, word, "#{form.text} (#{form.label}) should deinflect to #{word}"
      end
    end
  end
end
