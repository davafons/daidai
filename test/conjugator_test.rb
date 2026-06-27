# frozen_string_literal: true

require_relative "test_helper"

# Golden tests for the conjugator. Every assertion is an externally-verifiable,
# well-known Japanese form — the linguistic truth a learner would recognise —
# not a snapshot of whatever the implementation happens to emit. Forms are
# pulled through the public Result#grid / Form API.
#
# Quadrant keys are [negative, polite]:
#   [false, false] plain affirmative   [false, true] polite affirmative
#   [true,  false] plain negative      [true,  true] polite negative
class ConjugatorTest < Minitest::Test
  # Conjugation ids (see conj.csv).
  NON_PAST    = 1
  PAST        = 2
  TE          = 3 # Conjunctive (~te)
  PROVISIONAL = 4 # ~eba
  POTENTIAL   = 5
  PASSIVE     = 6
  CAUSATIVE   = 7
  CAUS_PASS   = 8 # Causative-Passive
  VOLITIONAL  = 9
  IMPERATIVE  = 10
  CONDITIONAL = 11 # ~tara

  PLAIN  = [ false, false ].freeze
  POLITE = [ false, true ].freeze
  NEG    = [ true, false ].freeze

  def conjugate(pos, kanji: nil, reading: nil)
    Daidai::Conjugator.conjugate(kanji: kanji, reading: reading, pos: pos)
  end

  # The Form occupying one (conjugation, quadrant) cell.
  def cell(result, conjugation, quadrant = PLAIN)
    result.grid(conjugation).fetch(quadrant)
  end

  # ── GODAN: 書く (v5k), the full paradigm ──

  def test_kaku_dictionary_form
    r = conjugate("v5k", kanji: "書く", reading: "かく")
    assert_equal "書く", cell(r, NON_PAST).kanji
    assert_equal "かく", cell(r, NON_PAST).reading
  end

  def test_kaku_negative
    r = conjugate("v5k", kanji: "書く", reading: "かく")
    assert_equal "書かない", cell(r, NON_PAST, NEG).kanji
  end

  def test_kaku_past
    r = conjugate("v5k", kanji: "書く", reading: "かく")
    assert_equal "書いた", cell(r, PAST).kanji
  end

  def test_kaku_te
    r = conjugate("v5k", kanji: "書く", reading: "かく")
    assert_equal "書いて", cell(r, TE).kanji
  end

  def test_kaku_masu_is_polite_non_past
    r = conjugate("v5k", kanji: "書く", reading: "かく")
    assert_equal "書きます", cell(r, NON_PAST, POLITE).kanji
  end

  def test_kaku_potential
    r = conjugate("v5k", kanji: "書く", reading: "かく")
    assert_equal "書ける", cell(r, POTENTIAL).kanji
  end

  def test_kaku_passive
    r = conjugate("v5k", kanji: "書く", reading: "かく")
    assert_equal "書かれる", cell(r, PASSIVE).kanji
  end

  def test_kaku_causative
    r = conjugate("v5k", kanji: "書く", reading: "かく")
    assert_equal "書かせる", cell(r, CAUSATIVE).kanji
  end

  def test_kaku_causative_passive
    r = conjugate("v5k", kanji: "書く", reading: "かく")
    assert_equal "書かせられる", cell(r, CAUS_PASS).kanji
  end

  def test_kaku_volitional
    r = conjugate("v5k", kanji: "書く", reading: "かく")
    assert_equal "書こう", cell(r, VOLITIONAL).kanji
  end

  def test_kaku_imperative
    r = conjugate("v5k", kanji: "書く", reading: "かく")
    assert_equal "書け", cell(r, IMPERATIVE).kanji
  end

  def test_kaku_provisional
    r = conjugate("v5k", kanji: "書く", reading: "かく")
    assert_equal "書けば", cell(r, PROVISIONAL).kanji
  end

  def test_kaku_conditional
    r = conjugate("v5k", kanji: "書く", reading: "かく")
    assert_equal "書いたら", cell(r, CONDITIONAL).kanji
  end

  # ── GODAN: euphonic (~te / ~ta) changes across every ending ──

  def test_oyogu_g_te_and_past_voice
    r = conjugate("v5g", kanji: "泳ぐ", reading: "およぐ")
    assert_equal "泳いで", cell(r, TE).kanji
    assert_equal "泳いだ", cell(r, PAST).kanji
  end

  def test_hanasu_s_te
    r = conjugate("v5s", kanji: "話す", reading: "はなす")
    assert_equal "話して", cell(r, TE).kanji
  end

  def test_matsu_t_te
    r = conjugate("v5t", kanji: "待つ", reading: "まつ")
    assert_equal "待って", cell(r, TE).kanji
  end

  def test_shinu_n_te
    r = conjugate("v5n", kanji: "死ぬ", reading: "しぬ")
    assert_equal "死んで", cell(r, TE).kanji
  end

  def test_asobu_b_te
    r = conjugate("v5b", kanji: "遊ぶ", reading: "あそぶ")
    assert_equal "遊んで", cell(r, TE).kanji
  end

  def test_nomu_m_te
    r = conjugate("v5m", kanji: "飲む", reading: "のむ")
    assert_equal "飲んで", cell(r, TE).kanji
  end

  def test_toru_r_te
    r = conjugate("v5r", kanji: "取る", reading: "とる")
    assert_equal "取って", cell(r, TE).kanji
  end

  def test_kau_u_paradigm
    r = conjugate("v5u", kanji: "買う", reading: "かう")
    assert_equal "買わない", cell(r, NON_PAST, NEG).kanji
    assert_equal "買って", cell(r, TE).kanji
    assert_equal "買おう", cell(r, VOLITIONAL).kanji
    assert_equal "買います", cell(r, NON_PAST, POLITE).kanji
  end

  # ── IRREGULAR GODAN: 行く takes ～って, not the regular ～いて ──

  def test_iku_irregular_te_and_past
    r = conjugate("v5k-s", kanji: "行く", reading: "いく")
    assert_equal "行って", cell(r, TE).kanji
    assert_equal "行った", cell(r, PAST).kanji
    refute_equal "行いて", cell(r, TE).kanji
  end

  # ── IRREGULAR: ある (v5r-i) loses its stem in the negative ──

  def test_aru_negative_is_nai
    r = conjugate("v5r-i", reading: "ある")
    assert_equal "ない", cell(r, NON_PAST, NEG).reading
  end

  def test_aru_past
    r = conjugate("v5r-i", reading: "ある")
    assert_equal "あった", cell(r, PAST).reading
  end

  def test_aru_past_negative
    r = conjugate("v5r-i", reading: "ある")
    assert_equal "なかった", cell(r, PAST, NEG).reading
  end

  # ── ICHIDAN: 食べる (v1) ──

  def test_taberu_negative
    r = conjugate("v1", kanji: "食べる", reading: "たべる")
    assert_equal "食べない", cell(r, NON_PAST, NEG).kanji
  end

  def test_taberu_te
    r = conjugate("v1", kanji: "食べる", reading: "たべる")
    assert_equal "食べて", cell(r, TE).kanji
  end

  def test_taberu_potential
    r = conjugate("v1", kanji: "食べる", reading: "たべる")
    assert_equal "食べられる", cell(r, POTENTIAL).kanji
  end

  def test_taberu_imperative
    r = conjugate("v1", kanji: "食べる", reading: "たべる")
    assert_equal "食べろ", cell(r, IMPERATIVE).kanji
  end

  def test_taberu_volitional
    r = conjugate("v1", kanji: "食べる", reading: "たべる")
    assert_equal "食べよう", cell(r, VOLITIONAL).kanji
  end

  def test_taberu_masu
    r = conjugate("v1", kanji: "食べる", reading: "たべる")
    assert_equal "食べます", cell(r, NON_PAST, POLITE).kanji
  end

  # ── IRREGULAR: する (vs-i) ──

  def test_suru_negative
    r = conjugate("vs-i", reading: "する")
    assert_equal "しない", cell(r, NON_PAST, NEG).reading
  end

  def test_suru_potential_is_dekiru
    r = conjugate("vs-i", reading: "する")
    assert_equal "できる", cell(r, POTENTIAL).reading
  end

  def test_suru_imperative
    r = conjugate("vs-i", reading: "する")
    assert_equal "しろ", cell(r, IMPERATIVE).reading
  end

  def test_suru_te
    r = conjugate("vs-i", reading: "する")
    assert_equal "して", cell(r, TE).reading
  end

  # ── IRREGULAR: 来る (vk) — kanji stays 来, reading shifts こ／き／く ──

  def test_kuru_negative_kanji_and_reading
    r = conjugate("vk", kanji: "来る", reading: "くる")
    assert_equal "来ない", cell(r, NON_PAST, NEG).kanji
    assert_equal "こない", cell(r, NON_PAST, NEG).reading
  end

  def test_kuru_masu_kanji_and_reading
    r = conjugate("vk", kanji: "来る", reading: "くる")
    assert_equal "来ます", cell(r, NON_PAST, POLITE).kanji
    assert_equal "きます", cell(r, NON_PAST, POLITE).reading
  end

  def test_kuru_te_kanji_and_reading
    r = conjugate("vk", kanji: "来る", reading: "くる")
    assert_equal "来て", cell(r, TE).kanji
    assert_equal "きて", cell(r, TE).reading
  end

  def test_kuru_imperative_kanji_and_reading
    r = conjugate("vk", kanji: "来る", reading: "くる")
    assert_equal "来い", cell(r, IMPERATIVE).kanji
    assert_equal "こい", cell(r, IMPERATIVE).reading
  end

  def test_kuru_volitional_reading
    r = conjugate("vk", kanji: "来る", reading: "くる")
    assert_equal "こよう", cell(r, VOLITIONAL).reading
  end

  # ── I-ADJECTIVE: 高い (adj-i) ──

  def test_takai_negative
    r = conjugate("adj-i", kanji: "高い", reading: "たかい")
    assert_equal "高くない", cell(r, NON_PAST, NEG).kanji
  end

  def test_takai_past
    r = conjugate("adj-i", kanji: "高い", reading: "たかい")
    assert_equal "高かった", cell(r, PAST).kanji
  end

  def test_takai_te
    r = conjugate("adj-i", kanji: "高い", reading: "たかい")
    assert_equal "高くて", cell(r, TE).kanji
  end

  def test_takai_polite_non_past
    r = conjugate("adj-i", kanji: "高い", reading: "たかい")
    assert_equal "高いです", cell(r, NON_PAST, POLITE).kanji
  end

  # ── IRREGULAR I-ADJECTIVE: いい (adj-ix) inflects off the よ- stem ──

  def test_ii_non_past_stays_ii
    r = conjugate("adj-ix", reading: "いい")
    assert_equal "いい", cell(r, NON_PAST).reading
  end

  def test_ii_negative
    r = conjugate("adj-ix", reading: "いい")
    assert_equal "よくない", cell(r, NON_PAST, NEG).reading
  end

  def test_ii_past
    r = conjugate("adj-ix", reading: "いい")
    assert_equal "よかった", cell(r, PAST).reading
  end

  def test_ii_te
    r = conjugate("adj-ix", reading: "いい")
    assert_equal "よくて", cell(r, TE).reading
  end

  # ── NA-ADJECTIVE: 静か (adj-na) conjugates through the copula ──

  def test_shizuka_non_past
    r = conjugate("adj-na", kanji: "静か", reading: "しずか")
    assert_equal "静かだ", cell(r, NON_PAST).kanji
  end

  def test_shizuka_polite
    r = conjugate("adj-na", kanji: "静か", reading: "しずか")
    assert_equal "静かです", cell(r, NON_PAST, POLITE).kanji
  end

  def test_shizuka_negative
    r = conjugate("adj-na", kanji: "静か", reading: "しずか")
    assert_equal "静かではない", cell(r, NON_PAST, NEG).kanji
  end

  def test_shizuka_past
    r = conjugate("adj-na", kanji: "静か", reading: "しずか")
    assert_equal "静かだった", cell(r, PAST).kanji
  end

  # ── VS NOUN: 勉強 (vs) conjugates by appending する ──

  def test_benkyou_non_past
    r = conjugate("vs", kanji: "勉強", reading: "べんきょう")
    assert_equal "勉強する", cell(r, NON_PAST).kanji
  end

  def test_benkyou_negative
    r = conjugate("vs", kanji: "勉強", reading: "べんきょう")
    assert_equal "勉強しない", cell(r, NON_PAST, NEG).kanji
  end

  def test_benkyou_past
    r = conjugate("vs", kanji: "勉強", reading: "べんきょう")
    assert_equal "勉強した", cell(r, PAST).kanji
  end
end
