class WordsController < ApplicationController

  def click_search
    @query = params[:q]
    # API設計：参考：https://qiita.com/mogulla3/items/a4bff2e569dfa7da1896
    # [URI]
    # URI.parseは与えられたURIからURI::Genericのサブクラスのインスタンスを返す
    # -> 今回はHTTPプロトコルなのでURI::HTTPクラスのインスタンスが返される
    #
    # オブジェクトからは以下のようにして構成要素を取得できる
    # uri.scheme => 'http'
    # uri.host   => 'mogulla3.com'
    # uri.port   => 4567
    # uri.path   => ''
    # uri.query  => 'param1=foo&param2=bar+baz&param3=%E3%81%82'
    params = {dictionary_id: '1', keyword: @query}
    uri = URI.parse("https://www.booqs.net/#{@locale}/api/v1/extensions/words/search")


    begin
      response = Net::HTTP.post_form(uri, params)
      # [レスポンス処理]
      # 2xx系以外は失敗として終了することにする
      # ※ リダイレクト対応できると良いな..
      #
      # ステータスコードに応じてレスポンスのクラスが異なる
      # 1xx系 => Net::HTTPInformation
      # 2xx系 => Net::HTTPSuccess
      # 3xx系 => Net::HTTPRedirection
      # 4xx系 => Net::HTTPClientError
      # 5xx系 => Net::HTTPServerError
      case response
        # 2xx系
      when Net::HTTPSuccess
        # [JSONパース処理]
        # JSONオブジェクトをHashへパースする
        # JSON::ParserErrorが発生する可能性がある
        body = JSON.parse(response.body)
        @results = body['data']
        @dictionary = body['dictionary']
        @query = body['keyword']


        # 3xx系
      when Net::HTTPRedirection
        # リダイレクト先のレスポンスを取得する際は
        # response['Location']でリダイレクト先のURLを取得してリトライする必要がある
        # logger.warn("Redirection: code=#{response.code} message=#{response.message}")
        @error = "Redirection: code=#{response.code} message=#{response.message}"
      else
        # logger.error("HTTP ERROR: code=#{response.code} message=#{response.message}")
        @error = "HTTP ERROR: code=#{response.code} message=#{response.message}"
      end
      # [エラーハンドリング]
      # 各種処理で発生しうるエラーのハンドリング処理
      # 各エラーごとにハンドリング処理が書けるようにrescue節は小さい単位で書く
      # (ここでは全て同じ処理しか書いていない)
    rescue IOError => e
      @error = e.message
    rescue TimeoutError => e
      @error = e.message
    rescue JSON::ParserError => e
      @error = e.message
    rescue => e
      @error = e.message
    end

    respond_to do |format|
      format.html { redirect_to root_url }
      format.js
    end
  end
end
