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

  # Negative te-form (negative request / "without doing"). Yomitan has no rule for
  # 〜ないで; daidai adds it, resolving through the plain negative to the base across
  # every verb class. (〜なくて already resolves via the -て + negative chain.)
  def test_negative_te_naide
    assert_equal [ "-ないで", "negative" ], chain("食べないで", "食べる") # ichidan
    assert_equal [ "-ないで", "negative" ], chain("行かないで", "行く") # godan
    assert_equal [ "-ないで", "negative" ], chain("読まないで", "読む")
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
  # the dictionary word — including the negative te-form (食べないで / 食べなくて), which
  # daidai covers beyond Yomitan. The one plain form still not deinflected is the
  # negative imperative (prohibitive 〜な, 食べるな): 〜な is too ambiguous for a safe
  # rule, so it's left to the reader's dictionary-form matching.
  def test_round_trip_plain_forms
    cases = { "食べる" => "v1", "書く" => "v5k", "飲む" => "v5m" }
    cases.each do |word, pos|
      Daidai.conjugate(word, pos).forms.each do |form|
        next if form.polite? || form.text == word
        next if form.negative? && form.name == :imperative # prohibitive 〜な: intentionally uncovered

        terms = Daidai.deinflect(form.text).map(&:term)
        assert_includes terms, word, "#{form.text} (#{form.label}) should deinflect to #{word}"
      end
    end
  end

  # The obligation / prohibition constructions. Each strips only its helper and
  # hands the rest to a rule that already existed, so the chain shows the whole
  # derivation rather than a single opaque step.
  def test_obligation_via_provisional
    assert_equal %w[obligation -ば negative], chain("行かなければならない", "行く")
    assert_equal %w[obligation -ば negative], chain("行かなければなりません", "行く")
  end

  def test_obligation_via_te_form
    assert_equal %w[obligation negative], chain("行かなくてはいけない", "行く")
    assert_equal %w[obligation negative], chain("行かなくちゃいけない", "行く")
  end

  # The helper can be elided entirely and the obligation still reads.
  def test_obligation_with_the_helper_left_off
    assert_equal %w[obligation negative], chain("行かなくちゃ", "行く")
  end

  def test_obligation_via_to_and_neba
    assert_equal %w[obligation negative], chain("行かないといけない", "行く")
    assert_equal %w[obligation -ねば], chain("行かねばならない", "行く")
  end

  def test_obligation_reaches_irregular_verbs
    assert_equal %w[obligation -ば negative], chain("来なければならない", "来る")
    assert_equal %w[obligation -ば negative], chain("しなければならない", "する")
  end

  # Prohibition leaves the verb un-negated, which is what makes it the opposite
  # of obligation rather than another spelling of it.
  def test_prohibition
    assert_equal %w[prohibition -て], chain("食べてはいけない", "食べる")
    assert_equal %w[prohibition -て], chain("忘れてはならない", "忘れる")
  end

  def test_prohibition_after_a_voiced_te_form
    assert_equal %w[prohibition -て], chain("読んではいけない", "読む")
    assert_equal %w[prohibition -て], chain("遊んじゃだめ", "遊ぶ")
  end

  def test_obligation_and_prohibition_are_labelled_as_opposites
    assert_equal "obligation (must)", Daidai::Deinflector.label("obligation")
    assert_equal "prohibition (must not)", Daidai::Deinflector.label("prohibition")
  end

  # A shorter suffix shadows a longer one: てはいけない matches inside なくてはいけない
  # and てもいい inside なくてもいい, so both readings are reachable. Consumers pick by
  # chain length (Inflection.best), so the negated construction must come out
  # strictly shorter or the wrong label wins by accident.
  def shortest(surface, lemma)
    Daidai.deinflect(surface).select { |d| d.term == lemma }.min_by { |d| d.inflections.size }
  end

  def test_a_negated_construction_outranks_the_shorter_suffix_inside_it
    assert_equal "obligation", shortest("行かなくてはいけない", "行く").inflections.first
    assert_equal "obligation", shortest("行かなくちゃいけない", "行く").inflections.first
    assert_equal "exemption", shortest("行かなくてもいい", "行く").inflections.first
  end

  # The four-part set learners meet together: must / must not / may / need not.
  def test_permission
    assert_equal %w[permission -て], chain("行ってもいい", "行く")
    assert_equal %w[permission -て], chain("読んでもいい", "読む")
    assert_equal %w[permission -て], chain("食べてもかまわない", "食べる")
  end

  def test_exemption
    assert_equal %w[exemption negative], chain("行かなくてもいい", "行く")
    assert_equal %w[exemption negative], chain("食べなくてもいい", "食べる")
  end

  # The helper is an i-adjective, so gating on adj-i lets its own inflection
  # deinflect first and the construction still resolves in the past.
  def test_a_construction_still_resolves_when_its_helper_inflects
    assert_equal %w[-た obligation -ば negative], chain("行かなければならなかった", "行く")
    assert_equal %w[-た prohibition -て], chain("食べてはいけなかった", "食べる")
  end

  # The rest of the て-auxiliary family, alongside -おく and -しまう.
  def test_te_auxiliaries
    assert_equal %w[-てみる -て], chain("読んでみる", "読む")
    assert_equal %w[-てある -て], chain("置いてある", "置く")
    assert_equal %w[-ていく -て], chain("増えていく", "増える")
    assert_equal %w[-てくる -て], chain("増えてくる", "増える")
  end

  # conditionsIn is the AUXILIARY's own verb class, which is what lets the
  # auxiliary conjugate and the whole thing still reach the verb.
  def test_a_te_auxiliary_that_is_itself_inflected
    assert_equal %w[-た -てみる -て], chain("読んでみた", "読む")
    assert_equal %w[-たい -てみる -て], chain("読んでみたい", "読む")
  end

  def test_beki
    assert_equal %w[-べき], chain("行くべき", "行く")
    assert_equal %w[-べき], chain("食べるべき", "食べる")
    assert_equal %w[-べき], chain("すべき", "する")
  end

  # 連用形 suffixes with nothing to hand off to: one rule per verb class, derived
  # from -たい's rule set so the coverage is identical by construction.
  def test_simultaneous_action
    assert_equal %w[-ながら], chain("食べながら", "食べる")
    assert_equal %w[-ながら], chain("読みながら", "読む")
    assert_equal %w[-ながら], chain("しながら", "する")
    assert_equal %w[-ながら], chain("来ながら", "来る")
    assert_equal %w[-つつ], chain("読みつつ", "読む")
  end

  def test_easy_and_hard_to_do
    assert_equal %w[-やすい], chain("読みやすい", "読む")
    assert_equal %w[-やすい], chain("食べやすい", "食べる")
    assert_equal %w[-にくい], chain("読みにくい", "読む")
  end

  # They are i-adjectives, so they conjugate and the verb is still reachable.
  def test_easy_and_hard_to_do_when_themselves_inflected
    assert_equal %w[-た -やすい], chain("読みやすかった", "読む")
    assert_equal %w[negative -にくい], chain("書きにくくない", "書く")
  end

  # Aspectual compound verbs. The auxiliary is a verb, so conditionsIn is its own
  # class and it may conjugate; both the kana and kanji spellings are covered
  # because JMdict and real text use each.
  def test_aspectual_compound_verbs
    assert_equal %w[-始める], chain("読み始める", "読む")
    assert_equal %w[-はじめる], chain("読みはじめる", "読む")
    assert_equal %w[-続ける], chain("読み続ける", "読む")
    assert_equal %w[-終わる], chain("読み終わる", "読む")
  end

  def test_an_aspectual_auxiliary_that_is_itself_inflected
    assert_equal %w[-た -始める], chain("読み始めた", "読む")
  end

  # The benefactives: who the action is done for. Same handoff as -てみる, and safer
  # than a bare 連用形 suffix because the literal て is required.
  def test_benefactives
    assert_equal %w[-てあげる -て], chain("読んであげる", "読む")
    assert_equal %w[-てくれる -て], chain("読んでくれる", "読む")
    assert_equal %w[-てもらう -て], chain("読んでもらう", "読む")
    assert_equal %w[-ていただく -て], chain("教えていただく", "教える")
    assert_equal %w[-てくださる -て], chain("書いてくださる", "書く")
    assert_equal %w[-た -てもらう -て], chain("読んでもらった", "読む")
  end

  # 〜だす, 〜なおす and 〜きる are deliberately absent. Unlike begin/finish they
  # lexicalise, and the dictionary already carries them:
  # 見直す is "to review", not "to see again", and every 〜だす compound checked
  # (泣き出す, 降り出す, 言い出す, 走り出す, 笑い出す, 動き出す) is a JMdict entry already.
  # A rule would win nothing there while 出す as a main verb is everywhere: it read
  # 外に出す as に出す ("煮出す"). These stay the dictionary's job.
  def test_lexicalised_compounds_are_left_to_the_dictionary
    assert_nil chain("見直す", "見る")
    assert_nil chain("読み直す", "読む")
    assert_nil chain("泣き出す", "泣く")
  end

  # The commonest polite request there is. ください is くださる's irregular
  # imperative and does not conjugate further, so -てくださる never matched it.
  def test_polite_request
    assert_equal %w[-てください -て], chain("読んでください", "読む")
    assert_equal %w[-てください -て], chain("来てください", "来る")
    assert_equal %w[-てください -ないで negative], chain("食べないでください", "食べる")
  end

  # More 連用形 suffixes. Safe to add where the auxiliary is not also a common
  # standalone verb: 〜かける is not here for the same reason 〜だす is not, the
  # substring にかける strips to にる (煮る), a real word.
  def test_further_renyoukei_suffixes
    assert_equal %w[-がち], chain("忘れがち", "忘れる")
    assert_equal %w[-っぱなし], chain("出しっぱなし", "出す")
    assert_equal %w[-かねる], chain("分かりかねる", "分かる")
  end

  def test_kakeru_is_left_out_like_dasu
    assert_nil chain("気にかける", "にる")
    assert_nil chain("読みかける", "読む")
  end
end
