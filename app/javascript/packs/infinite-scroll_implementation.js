
$(document).on('turbolinks:load', function () {

    // 無限スクロール
    var $infiniteScroll = $('#infinite-scroll');
    $infiniteScroll.infiniteScroll({
        // pathはセレクタで選択しないとcheckLastPageが動かない。
        path: "a[rel='next']",
        checkLastPage: true,
        append: ".append-content",
        history: false,
        prefill: false,
        status: '.page-load-status',
        hideNav: '.pagination',
        appendCallback: true
    });

    // ボタンで追加要素を読み込む無限スクロール
    var $infiniteScrollButton = $('#infinite-scroll-button');
    $infiniteScrollButton.infiniteScroll({
        // pathはセレクタで選択しないとcheckLastPageが動かない。
        path: "a[rel='next']",
        append: ".append-content",
        button: '.view-more-button',
        scrollThreshold: false,
        status: '.page-load-status',
        hideNav: '.pagination',
    });

});