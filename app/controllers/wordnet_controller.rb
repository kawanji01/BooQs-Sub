class WordnetController < ApplicationController

  def home
    database = SQLite3::Database.new('db/wnjpn.sqlite')
    @data = database.execute("SELECT name, sense.lang, word.lemma, synset_def.def, synset_ex.def FROM synset
JOIN synset_def ON synset.synset = synset_def.synset
JOIN synset_ex ON synset.synset = synset_ex.synset
JOIN sense ON synset.synset = sense.synset
JOIN word ON sense.wordid = word.wordid
WHERE synset_def.lang='jpn' AND word.lang='jpn' AND synset_ex.lang='jpn'
LIMIT 5")
  end

  def ja_ja_dict
    database = SQLite3::Database.new('db/wnjpn.sqlite')
    # 条件
    # sunset_exは、日本語の場合は適切な例文にならないのでjoinしない。
    # 必要なのは、日本語の項目 / 日本語の定義
    # あとで類語を取得できるように、一応synsetだけはdbに保存しておく。
    # 重複させない。
    dictionaries = database.execute("SELECT DISTINCT synset.synset, word.lemma, synset_def.def FROM synset
JOIN synset_def ON synset.synset = synset_def.synset
JOIN sense ON synset.synset = sense.synset
JOIN word ON sense.wordid = word.wordid
WHERE synset_def.lang='jpn' AND word.lang='jpn'
LIMIT 1000")

    entries = []
    already_added = []
    dictionaries.each do |dict|
      key = "#{dict[1] + dict[0]}"

      next if already_added.include?(key)

      duplications = dictionaries.find_all { |d| d[1] == dict[1] && d[0] == dict[0] }

      hash = { entry: dict[1],
               def: duplications.map { |dup| dup[2] }.join(' / '),
               exp: duplications.map { |dup| dup[2] }.join("\n"),
               synset: dict[0]
      }
      #hash = { entry: dict[1],
      #         def: dict[2],
      #         exp: dict[3],
      #         synset: dict[0]
      #}

      entries << hash
      already_added << key
    end
    @entries = entries
  end

  def en_en_dict
    database = SQLite3::Database.new('db/wnjpn.sqlite')
    # 条件
    # 必要なのは、英語の項目 / 英語の定義 / 英語の例文
    # あとで類語を取得できるように、一応synsetだけはdbに保存しておく。
    # 重複させない。
    dictionaries = database.execute("SELECT DISTINCT synset.synset, word.lemma, synset_def.def FROM synset
JOIN synset_def ON synset.synset = synset_def.synset
JOIN sense ON synset.synset = sense.synset
JOIN word ON sense.wordid = word.wordid
WHERE synset_def.lang='eng' AND word.lang='eng'
LIMIT 20000")

    entries = []
    already_added = []
    dictionaries.each do |dict|
      key = "#{dict[1] + dict[0]}"
      next if already_added.include?(key)

      # 項目とsynset（意味）の両方が重複しているものを集める。項目の重複だけ検証すると、必要なsynsetまで破棄されることになる。
      duplications = dictionaries.find_all { |d| d[1] == dict[1] && d[0] == dict[0] }
      hash = { entry: dict[1],
               def: duplications.map { |dup| dup[2] }.join(' / '),
               exp: duplications.map { |dup| dup[2] }.join("\n"),
               synset: dict[0]
      }
      #hash = { entry: dict[1],
      #         def: dict[2],
      #         exp: dict[3],
      #         synset: dict[0]
      #}

      entries << hash
      already_added << key
    end
    @entries = entries
  end
end
