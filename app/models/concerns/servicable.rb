# 参考 https://qiita.com/rin_mu/items/6e51f38cd1d7f85bb19c
# 参考 https://techracho.bpsinc.jp/hachi8833/2017_10_16/46482
#
# Servicable サービスクラスでincludeする
module Servicable
  extend ActiveSupport::Concern

  # パブリックに呼び出せる、サービスクラスのクラスメソッド。
  # callの戻り値はサービスクラスのインスタンスを返すことを強制している。
  class_methods do
    # 「*args」は可変長引数（いくつでも指定できる引数）を示す ref: https://qiita.com/metheglin/items/306e81c95f8a5cdea296#%E5%8F%AF%E5%A4%89%E9%95%B7%E5%BC%95%E6%95%B0%E3%82%A2%E3%82%B9%E3%82%BF%E3%83%AA%E3%82%B9%E3%82%AF
    def call(*args)
      service = new(*args)
      # ルール： サービスクラスでは必ずService#callを設定しなければならない。
      service.call
      service
    end
  end
end

# サービスクラスの実装ルール
# - パブリックなメソッドは new, callのみ。他はprivateメソッドにしてカプセル化する。（単一責任の原則）
# - 命名規則：〇〇er, 〇〇or （ArticleDestroyer, CommentCreator）
# - 責務：１つのビジネスロジックのみ
# - 呼び出し方：クラスメソッドのcallを呼ぶ（Servicableを参照）
#
# こうした実装を「スタティックファクトリーメソッドパターン」と呼ぶらしい。
#
# 例： https://qiita.com/rin_mu/items/6e51f38cd1d7f85bb19c
# class CommentCreator
#   include Servicable
#   ATTRIBUTES = %i[comment successful]
#
#   attr_reader(*ATTRIBUTES)
#
#   def initialize(comment_attributes)
#     self.comment = Comment.new(comment_attributes)
#   end
#
#   def call
#     if self.successful = comment.save
#       comment.increment_thread_count
#       comment.notify_to_thread_watchers
#     end
#   end
#
#   private
#
#   attr_writer(*ATTRIBUTES)
# end