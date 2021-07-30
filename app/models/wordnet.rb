class Wordnet < ApplicationRecord
  require 'csv'

  def self.distinct_size
    database = SQLite3::Database.new('db/wnjpn.sqlite')
    dictionaries = database.execute("SELECT DISTINCT synset.synset, word.lemma, synset_def.def FROM synset
JOIN synset_def ON synset.synset = synset_def.synset
JOIN sense ON synset.synset = sense.synset
JOIN word ON sense.wordid = word.wordid
WHERE synset_def.lang='jpn' AND word.lang='jpn'")
    p dictionaries.size
  end

  def self.create_ja_ja_dict
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
WHERE synset_def.lang='jpn' AND word.lang='jpn'")


    csv_data = CSV.generate do |csv|
      header = %w[wordnet_synset entry meaning explanation lang_number_of_entry lang_number_of_meaning dictionary_id created_at updated_at]
      csv << header


      already_added = []
      dictionaries.each_with_index do |dict, i|
        # 項目とsynset（意味）の両方が重複しているものを集める。項目の重複だけ検証すると、必要なsynsetまで破棄されることになる。
        key = "#{dict[1] + dict[0]}"
        next if already_added.include?(key)

        current_time = DateTime.now.to_s

        duplications = dictionaries.find_all { |d| d[1] == dict[1] && d[0] == dict[0] }

        hash = { entry: dict[1],
                 meaning: duplications.map { |dup| dup[2] }.join(' / '),
                 explanation: duplications.map { |dup| dup[2] }.join("\n"),
                 synset: dict[0]
        }
        already_added << key
        p i if i % 1000 == 0

        values = [hash[:synset], hash[:entry], hash[:meaning], hash[:explanation], 44, 44, 3, current_time, current_time]

        csv << values
      end
    end

    current_time = DateTime.now.to_s
    File.open('./' + current_time + '_ja_ja_dict.csv', 'w') do |file|
      file.write(csv_data)
    end
  end



  def self.create_en_en_dict
    database = SQLite3::Database.new('db/wnjpn.sqlite')
    # 条件
    # 必要なのは、英語の項目 / 英語の定義
    # あとで類語を取得できるように、一応synsetだけはdbに保存しておく。
    # 重複させない。
    dictionaries = database.execute("SELECT DISTINCT synset.synset, word.lemma, synset_def.def FROM synset
JOIN synset_def ON synset.synset = synset_def.synset
JOIN sense ON synset.synset = sense.synset
JOIN word ON sense.wordid = word.wordid
WHERE synset_def.lang='eng' AND word.lang='eng'")


    csv_data = CSV.generate do |csv|
      header = %w[wordnet_synset entry meaning explanation lang_number_of_entry lang_number_of_meaning dictionary_id created_at updated_at]
      csv << header


      already_added = []
      dictionaries.each_with_index do |dict, i|
        key = "#{dict[1] + dict[0]}"

        next if already_added.include?(key)

        current_time = DateTime.now.to_s

        # 項目とsynset（意味）の両方が重複しているものを集める。項目の重複だけ検証すると、必要なsynsetまで破棄されることになる。
        duplications = dictionaries.find_all { |d| d[1] == dict[1] && d[0] == dict[0] }

        hash = { entry: dict[1],
                 meaning: "#{duplications.map { |dup| dup[2] }.join(' / ')}",
                 explanation: "#{duplications.map { |dup| dup[2] }.join("\n")}",
                 synset: dict[0]
        }
        values = [hash[:synset], hash[:entry], hash[:meaning], hash[:explanation], 21, 21, 4, current_time, current_time]

        csv << values

        already_added << key
        p i if i % 1000 == 0
      end
    end

    current_time = DateTime.now.to_s

    File.open('./' + current_time + '_en_en_dict.csv', 'w') do |file|
      file.write(csv_data)
    end
  end


  def self.en_en_count
    database = SQLite3::Database.new('db/wnjpn.sqlite')
    # 条件
    # 必要なのは、英語の項目 / 英語の定義
    # あとで類語を取得できるように、一応synsetだけはdbに保存しておく。
    # 重複させない。
    dictionaries = database.execute("SELECT DISTINCT synset.synset, word.lemma, synset_def.def FROM synset
JOIN synset_def ON synset.synset = synset_def.synset
JOIN sense ON synset.synset = sense.synset
JOIN word ON sense.wordid = word.wordid
WHERE synset_def.lang='eng' AND word.lang='eng'")
    #p dictionaries.size
  end


  def self.ja_ja_count
    database = SQLite3::Database.new('db/wnjpn.sqlite')
    # 条件
    # 必要なのは、英語の項目 / 英語の定義
    # あとで類語を取得できるように、一応synsetだけはdbに保存しておく。
    # 重複させない。
    dictionaries = database.execute("SELECT DISTINCT synset.synset, word.lemma, synset_def.def FROM synset
JOIN synset_def ON synset.synset = synset_def.synset
JOIN sense ON synset.synset = sense.synset
JOIN word ON sense.wordid = word.wordid
WHERE synset_def.lang='jpn' AND word.lang='jpn'")
  end


end