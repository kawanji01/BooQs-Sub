
$(document).on('turbolinks:load', function () {

    // ローディング画面を表示する（モーダル用）
    $(document).on("click", ".loading-show-btn", function () {
        $(this).next('.loading').removeClass('is-hide');
        // スマホのキーボードを閉じる
        $(".text-input-form").blur();
    });

    // layouts/application.html.erbに設置したローディング画面を表示する。
    $(document).on("click", ".main-loading-show-btn", function () {
        // nextではなく、nextAllを使う理由は、本番環境ではmainのすぐ後には<ins class="adsbygoogle adsbygoogle-noablate">が生成されるため。
        $("#main").nextAll('#loading').removeClass('is-hide');
        // スマホのキーボードを閉じる
        $(".text-input-form").blur();
    });


});
