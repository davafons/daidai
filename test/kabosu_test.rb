# frozen_string_literal: true

require_relative "test_helper"

# The optional kabosu-backed resolver. The 活用型 → JMdict POS mapping is pure
# and always tested; the live tokenizer path runs only when kabosu + a Sudachi
# dictionary are installed (otherwise it skips).
class KabosuTest < Minitest::Test
  def map(pos, lemma)
    Daidai::Kabosu.jmdict_pos(pos, lemma)
  end

  def test_godan_conjugation_types
    assert_equal "v5k", map(%w[動詞 一般 * * 五段-カ行 終止形], "書く")
    assert_equal "v5g", map(%w[動詞 一般 * * 五段-ガ行 終止形], "泳ぐ")
    assert_equal "v5s", map(%w[動詞 一般 * * 五段-サ行 終止形], "話す")
    assert_equal "v5m", map(%w[動詞 一般 * * 五段-マ行 終止形], "飲む")
    assert_equal "v5u", map(%w[動詞 一般 * * 五段-ワア行 終止形], "買う")
  end

  def test_ichidan_maps_to_v1
    assert_equal "v1", map(%w[動詞 一般 * * 下一段-バ行 終止形], "食べる")
    assert_equal "v1", map(%w[動詞 一般 * * 上一段-マ行 終止形], "見る")
  end

  def test_irregular_verbs
    assert_equal "vk",   map(%w[動詞 非自立可能 * * カ行変格 終止形], "来る")
    assert_equal "vs-i", map(%w[動詞 非自立可能 * * サ行変格 終止形], "する")
  end

  def test_lemma_overrides_for_subclass_irregulars
    # 行く is 五段-カ行 like 書く, but JMdict marks it v5k-s (行って, not 行いて).
    assert_equal "v5k-s", map(%w[動詞 非自立可能 * * 五段-カ行 終止形], "行く")
    # ある is 五段-ラ行, but its irregular negative (ない) makes it v5r-i.
    assert_equal "v5r-i", map(%w[動詞 非自立可能 * * 五段-ラ行 終止形], "ある")
  end

  def test_adjectives
    assert_equal "adj-i",  map(%w[形容詞 一般 * * 形容詞 終止形], "高い")
    assert_equal "adj-na", map(%w[形状詞 一般 * * * *], "静か")
  end

  def test_irregular_subclasses_not_expressed_by_the_conjugation_type
    {
      "問う" => %w[五段-ワア行 v5u-s],
      "くださる" => %w[五段-ラ行 v5aru],
      "なさる" => %w[五段-ラ行 v5aru],
      "いらっしゃる" => %w[五段-ラ行 v5aru]
    }.each do |lemma, (type, expected)|
      assert_equal expected, map([ "動詞", "一般", "*", "*", type, "終止形" ], lemma), lemma
    end
    assert_equal "adj-ix", map(%w[形容詞 一般 * * 形容詞 終止形], "いい")
  end

  def test_non_inflecting_pos_is_nil
    assert_nil map(%w[名詞 普通名詞 * * * *], "猫")
    assert_nil map(%w[助詞 格助詞 * * * *], "が")
    assert_nil map(%w[助動詞 * * * 助動詞-タ 終止形], "た")
    assert_nil map(%w[助動詞 * * * 助動詞-マス 終止形], "ます")
  end

  def test_honorific_spellings_keep_their_lemma_and_irregular_polite_form
    skip "kabosu / Sudachi dictionary not available" unless Daidai::Kabosu.available?

    {
      "くださる" => "くださいます", "下さる" => "下さいます",
      "なさる" => "なさいます", "為さる" => "為さいます",
      "いらっしゃる" => "いらっしゃいます",
      "おっしゃる" => "おっしゃいます", "仰る" => "仰います", "仰有る" => "仰有います",
      "ござる" => "ございます", "御座る" => "御座います"
    }.each do |lemma, polite|
      word = Daidai.conjugate(lemma)
      assert_equal lemma, word.word, lemma
      assert_equal "v5aru", word.pos, lemma
      assert_includes word.map(&:text), polite, lemma
      resolved = Daidai.conjugate(polite)
      assert_equal lemma, resolved.word, polite
      assert_equal "v5aru", resolved.pos, polite
    end
    assert_equal "おる", Daidai.conjugate("おる").word
    assert_equal "v5r", Daidai.conjugate("おる").pos
    %w[おっしゃった おっしゃらない おっしゃって おっしゃれば おっしゃい].each do |surface|
      assert_equal "おっしゃる", Daidai.conjugate(surface).word, surface
    end
  end

  def test_copula_auxiliaries_have_their_own_paradigm
    assert_equal "cop", map(%w[助動詞 * * * 助動詞-ダ 終止形], "だ")
    assert_equal "cop", map(%w[助動詞 * * * 助動詞-デス 終止形], "です")
  end

  def test_automatic_copulas_preserve_the_first_inflecting_word
    skip "kabosu / Sudachi dictionary not available" unless Daidai::Kabosu.available?

    { "だ" => "だ", "だった" => "だ", "です" => "です", "でした" => "です" }.each do |input, lemma|
      word = Daidai.conjugate(input)
      refute_nil word, input
      assert_equal lemma, word.word, input
      assert_equal "だった", word.past.to_s, input
    end
    assert_equal "静か", Daidai.conjugate("静かだった").word
    assert_equal "食べる", Daidai.conjugate("食べた").word
    assert_nil Daidai.conjugate("た")
  end

  def test_resolve_inflected_words
    skip "kabosu / Sudachi dictionary not available" unless Daidai::Kabosu.available?

    # word omitted POS → Sudachi resolves the lemma + POS, even when inflected.
    { "食べている" => %w[食べる 食べた], # progressive → ichidan
      "行った" => %w[行く 行った], # past → v5k-s irregular
      "高くない" => %w[高い 高かった], # negative adj → adj-i
      "した" => %w[する した], # → する (vs-i)
      "勉強した" => %w[勉強 勉強した],
      "問う" => %w[問う 問うた],
      "いい" => %w[いい よかった] }.each do |input, (lemma, past)|
      word = Daidai.conjugate(input)
      assert_equal lemma, word.word, "#{input} should resolve to #{lemma}"
      assert_equal past, word.past.to_s, "#{input} past form"
    end

    assert_nil Daidai.conjugate("猫"), "a noun resolves to nil"
  end

  def test_missing_dependency_raised_without_pos_or_kabosu
    skip "kabosu is available here" if Daidai::Kabosu.available?

    assert_raises(Daidai::Kabosu::MissingDependency) { Daidai.conjugate("食べる") }
  end
end
