# 読み込んだ字幕の文字列を、ユーザーが可読な形に整形するサービスクラス
# サービスクラスの設計は ref: https://qiita.com/chrischris0801/items/58a12d17a440b842db02
class Sanitizer
  include Servicable

  # 読み込みはパブリックに行えるようにする
  attr_reader :text
  # 引数は出来る限りnewで渡し、initializeでインスタンス化する
  def initialize(text)
    @text = text
  end

  # 1つのサービスにpublicなメソッドは、原則1つ（call）にする。
  def call
    # htmlタグと、末尾の不要な改行を取り除く。
    sanitized_text = Sanitize.clean(text).strip
    # 特殊文字で示された空白文字を可読な空白文字に変換する。
    # 問題が起きた動画の例： https://www.youtube.com/watch?v=-ojnMT0sylo&t=5s
    @text = sanitized_text.gsub(/\\h/, ' ')
  end

  private
  # 書き込みはクラス内でのみ許可する
  attr_writer :text
end