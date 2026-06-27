# frozen_string_literal: true

require_relative "test_helper"

# The public Daidai API surface: conjugatable?, the Word/Form/View interface,
# keyword modifiers, fluent views, dynamic access, and Enumerable behaviour.
class DaidaiTest < Minitest::Test
  def test_conjugatable_predicate
    assert Daidai.conjugatable?("v1")
    assert Daidai.conjugatable?("v5k")
    assert Daidai.conjugatable?("adj-i")
    assert Daidai.conjugatable?("adj-na")
    refute Daidai.conjugatable?("n")
    refute Daidai.conjugatable?("adj-no")
    refute Daidai.conjugatable?("adv")
    refute Daidai.conjugatable?("prt")
  end

  def test_array_pos_picks_first_conjugatable
    assert Daidai.conjugatable?(%w[n v5k])
    assert_equal "v5k", Daidai.conjugate("書く", %w[n v5k]).pos
  end

  def test_non_conjugatable_or_blank_returns_nil
    assert_nil Daidai.conjugate("猫", "n")
    assert_nil Daidai.conjugate("", "v5k")
    assert_nil Daidai.conjugate(nil, "v5k")
  end

  def test_word_introspection
    w = Daidai.conjugate("食べる", "v1")
    assert_equal "食べる", w.word
    assert_equal "v1", w.pos
    assert_equal :ichidan, w.kind
    assert_equal :non_past, w.conjugations.first
    assert_includes w.conjugations, :past
  end

  def test_reading_is_optional
    bare = Daidai.conjugate("書く", "v5k")
    assert_equal "書いた", bare.past.kanji
    assert_nil bare.past.reading

    with_reading = Daidai.conjugate("書く", "v5k", reading: "かく")
    assert_equal "書いた", with_reading.past.kanji
    assert_equal "かいた", with_reading.past.reading
  end

  def test_kana_word_is_its_own_reading
    w = Daidai.conjugate("する", "vs-i")
    assert_nil w.past.kanji
    assert_equal "した", w.past.reading
    assert_equal "した", w.past.to_s # falls back to the kana
  end

  def test_keyword_modifiers
    w = Daidai.conjugate("書く", "v5k")
    assert_equal "書く", w.non_past.to_s
    assert_equal "書かない",         w.non_past(negative: true).to_s
    assert_equal "書きます",         w.non_past(polite: true).to_s
    assert_equal "書きませんでした", w.past(negative: true, polite: true).to_s
  end

  def test_fluent_views_chain
    w = Daidai.conjugate("書く", "v5k")
    assert_equal "書きました", w.polite.past.to_s
    assert_equal "書かなかった", w.negative.past.to_s
    assert_equal "書きません",   w.polite.negative.non_past.to_s
    assert_equal "書かなくて",   w.negative.te.to_s
  end

  def test_bracket_access_matches_methods
    w = Daidai.conjugate("書く", "v5k")
    assert_equal w.past(polite: true), w[:past, polite: true]
    assert_equal w.non_past(negative: true), w.form(:non_past, negative: true)
  end

  def test_variants_returns_all_onums
    te_neg = Daidai.conjugate("書く", "v5k").variants(:te, negative: true).map(&:to_s)
    assert_includes te_neg, "書かなくて"
    assert_includes te_neg, "書かないで"
  end

  def test_primary_variant
    w = Daidai.conjugate("書く", "v5k")
    assert_predicate w.te(negative: true), :primary? # [] returns the primary (onum 1)
    variants = w.variants(:te, negative: true)
    assert_predicate variants.first, :primary?
    refute_predicate variants.last, :primary?
  end

  def test_word_is_enumerable
    w = Daidai.conjugate("書く", "v5k")
    assert_operator w.forms.size, :>, 10
    assert_equal w.forms.size, w.count
    assert(w.all?(Daidai::Form))
    assert(w.any? { |f| f.name == :past })
  end

  def test_form_aliases
    w = Daidai.conjugate("書く", "v5k")
    assert_equal w.non_past, w.dictionary
    assert_equal w.te, w.te_form
  end

  def test_form_metadata
    f = Daidai.conjugate("書く", "v5k").past(polite: true)
    assert_equal :past, f.name
    assert_equal "Past", f.label
    assert_predicate f, :polite?
    refute_predicate f, :negative?
  end

  def test_forms_constant
    assert_kind_of Hash, Daidai::FORMS
    assert_equal "Past", Daidai::FORMS[:past]
    assert_includes Daidai::FORMS.keys, :potential
  end
end
