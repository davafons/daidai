# frozen_string_literal: true

require_relative "test_helper"

# Smoke tests for the top-level Daidai.* API: the thin façade over the
# conjugator that apps actually call. Exhaustive form coverage lives in
# conjugator_test.rb; here we just confirm the public surface behaves.
class DaidaiTest < Minitest::Test
  # ── conjugatable? ──

  def test_conjugatable_true_for_verb
    assert Daidai.conjugatable?("v1")
    assert Daidai.conjugatable?("v5k")
    assert Daidai.conjugatable?("adj-i")
  end

  def test_not_conjugatable_for_plain_word_classes
    refute Daidai.conjugatable?("n")
    refute Daidai.conjugatable?("adj-no")
    refute Daidai.conjugatable?("adv")
    refute Daidai.conjugatable?("prt")
  end

  def test_conjugatable_picks_conjugatable_code_from_array
    assert Daidai.conjugatable?(%w[n v5k])
    refute Daidai.conjugatable?(%w[n adj-no])
  end

  # ── conjugate ──

  def test_conjugate_returns_result_with_forms
    result = Daidai.conjugate(kanji: "書く", reading: "かく", pos: "v5k")

    assert_instance_of Daidai::Result, result
    assert_equal "v5k", result.pos
    assert_equal :godan, result.kind
    refute_empty result.forms
  end

  def test_conjugate_dictionary_form_round_trips
    result = Daidai.conjugate(kanji: "書く", reading: "かく", pos: "v5k")
    dictionary = result.grid(1)[[ false, false ]]

    assert_equal "書く", dictionary.kanji
    assert_equal "かく", dictionary.reading
  end

  def test_conjugate_without_kanji
    result = Daidai.conjugate(reading: "する", pos: "vs-i")

    assert_equal :suru, result.kind
    assert_equal "しない", result.grid(1)[[ true, false ]].reading
  end

  def test_conjugate_returns_nil_for_non_conjugatable_pos
    assert_nil Daidai.conjugate(kanji: "犬", reading: "いぬ", pos: "n")
  end

  def test_conjugate_picks_first_conjugatable_code_from_array
    result = Daidai.conjugate(kanji: "書く", reading: "かく", pos: %w[n v5k])

    refute_nil result
    assert_equal "v5k", result.pos
  end

  # ── Result introspection ──

  def test_result_names_conjugations
    result = Daidai.conjugate(kanji: "書く", reading: "かく", pos: "v5k")

    assert_equal "Non-past", result.name(1)
    assert_equal "Past (~ta)", result.name(2)
    assert_includes result.conjugations, 1
  end
end
