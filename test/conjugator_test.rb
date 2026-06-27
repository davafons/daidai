# frozen_string_literal: true

require_relative "test_helper"

# Golden tests: linguistically-correct forms (external truth), exercised through
# the public Daidai.conjugate API across every supported word class.
class ConjugatorTest < Minitest::Test
  # Conjugate `word`/`pos` and return the primary form's displayed text.
  def text(word, pos, form, reading: nil, **mods)
    w = Daidai.conjugate(word, pos, reading: reading)
    refute_nil w, "#{word} (#{pos}) should be conjugatable"
    w.public_send(form, **mods)&.to_s
  end

  def test_godan_kaku_full_paradigm
    assert_equal "書く", text("書く", "v5k", :non_past)
    assert_equal "書かない",       text("書く", "v5k", :non_past, negative: true)
    assert_equal "書きます",       text("書く", "v5k", :non_past, polite: true)
    assert_equal "書きません",      text("書く", "v5k", :non_past, negative: true, polite: true)
    assert_equal "書いた", text("書く", "v5k", :past)
    assert_equal "書かなかった", text("書く", "v5k", :past, negative: true)
    assert_equal "書きました", text("書く", "v5k", :past, polite: true)
    assert_equal "書いて",         text("書く", "v5k", :te)
    assert_equal "書ける",         text("書く", "v5k", :potential)
    assert_equal "書かれる",       text("書く", "v5k", :passive)
    assert_equal "書かせる",       text("書く", "v5k", :causative)
    assert_equal "書かせられる", text("書く", "v5k", :causative_passive)
    assert_equal "書こう", text("書く", "v5k", :volitional)
    assert_equal "書け", text("書く", "v5k", :imperative)
    assert_equal "書けば", text("書く", "v5k", :provisional)
    assert_equal "書いたら", text("書く", "v5k", :conditional)
  end

  def test_godan_te_and_past_euphony_across_endings
    assert_equal "泳いで",  text("泳ぐ", "v5g", :te)
    assert_equal "泳いだ",  text("泳ぐ", "v5g", :past)
    assert_equal "話して",  text("話す", "v5s", :te)
    assert_equal "待って",  text("待つ", "v5t", :te)
    assert_equal "死んで",  text("死ぬ", "v5n", :te)
    assert_equal "遊んで",  text("遊ぶ", "v5b", :te)
    assert_equal "飲んで",  text("飲む", "v5m", :te)
    assert_equal "取って",  text("取る", "v5r", :te)
    assert_equal "買わない", text("買う", "v5u", :non_past, negative: true)
    assert_equal "買って",   text("買う", "v5u", :te)
    assert_equal "買おう",   text("買う", "v5u", :volitional)
  end

  def test_iku_irregular_euphony
    assert_equal "行って", text("行く", "v5k-s", :te) # not 行いて
    assert_equal "行った", text("行く", "v5k-s", :past)
  end

  def test_aru_irregular_negative
    assert_equal "ない", text("ある", "v5r-i", :non_past, negative: true)
    assert_equal "あった", text("ある", "v5r-i", :past)
    assert_equal "なかった", text("ある", "v5r-i", :past, negative: true)
  end

  def test_ichidan_taberu
    assert_equal "食べない", text("食べる", "v1", :non_past, negative: true)
    assert_equal "食べて", text("食べる", "v1", :te)
    assert_equal "食べられる", text("食べる", "v1", :potential)
    assert_equal "食べろ", text("食べる", "v1", :imperative)
    assert_equal "食べよう", text("食べる", "v1", :volitional)
  end

  def test_suru_irregular
    assert_equal "しない", text("する", "vs-i", :non_past, negative: true)
    assert_equal "できる", text("する", "vs-i", :potential)
    assert_equal "しろ",   text("する", "vs-i", :imperative)
    assert_equal "して",   text("する", "vs-i", :te)
  end

  # 来る exercises both the kanji form (constant 来) and the reading's vowel shift.
  def test_kuru_kanji_and_reading
    w = Daidai.conjugate("来る", "vk", reading: "くる")
    assert_equal "来ない", w.non_past(negative: true).kanji
    assert_equal "こない", w.non_past(negative: true).reading
    assert_equal "来ます", w.non_past(polite: true).kanji
    assert_equal "きます", w.non_past(polite: true).reading
    assert_equal "来て",   w.te.kanji
    assert_equal "きて",   w.te.reading
    assert_equal "来い",   w.imperative.kanji
    assert_equal "こい",   w.imperative.reading
  end

  def test_i_adjective
    assert_equal "高くない", text("高い", "adj-i", :non_past, negative: true)
    assert_equal "高かった", text("高い", "adj-i", :past)
    assert_equal "高くて", text("高い", "adj-i", :te)
    assert_equal "高いです", text("高い", "adj-i", :non_past, polite: true)
  end

  def test_ii_adjective_irregular_stem
    assert_equal "いい", text("いい", "adj-ix", :non_past)
    assert_equal "よくない", text("いい", "adj-ix", :non_past, negative: true)
    assert_equal "よかった", text("いい", "adj-ix", :past)
  end

  def test_na_adjective_via_copula
    assert_equal "静かだ", text("静か", "adj-na", :non_past)
    assert_equal "静かです", text("静か", "adj-na", :non_past, polite: true)
    assert_equal "静かではない", text("静か", "adj-na", :non_past, negative: true)
    assert_equal "静かだった", text("静か", "adj-na", :past)
  end

  def test_vs_noun_appends_suru
    assert_equal "勉強する", text("勉強", "vs", :non_past)
    assert_equal "勉強しない", text("勉強", "vs", :non_past, negative: true)
    assert_equal "勉強した", text("勉強", "vs", :past)
  end

  def test_remaining_godan_forms
    assert_equal "書き", text("書く", "v5k", :stem) # continuative / masu-stem
    assert_equal "書いたり", text("書く", "v5k", :alternative)
    assert_equal "書こう",    text("書く", "v5k", :volitional)
    assert_equal "書くな",    text("書く", "v5k", :imperative, negative: true) # prohibitive
    assert_equal "書かれます", text("書く", "v5k", :passive, polite: true)
  end
end
