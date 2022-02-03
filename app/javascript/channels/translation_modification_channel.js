import consumer from "./consumer"

consumer.subscriptions.create("TranslationModificationChannel", {
    connected() {
        // Called when the subscription is ready for use on the server
    },

    disconnected() {
        // Called when the subscription has been terminated by the server
    },

    received(data) {
        var $article = $("#article-" + data['article']['public_uid']);
        if ($article.length !== 0) {
            modifyTranslation(data);
        }
    }
});


function modifyTranslation(data) {
    var articleUid = data['article']['public_uid'];
    var langCode = data['lang_code'];
    var editorToken = data['editor_token'];
    var message = data['message'];
    var $feedbackWrapper;


    if (data['passage'] == null) {
        //////// タイトルの翻訳の更新 ///////
        // 編集ユーザーの編集フォームを閉じて、コンテンツを更新する。
        $('#article-title-' + articleUid + '-translation-lang-' + langCode + '-edit-form-uid-' + editorToken).replaceWith(data['html']);
        // 他の閲覧ユーザーのコンテンツを更新する。
        $('#article-title-' + articleUid + '-translation-lang-' + langCode).replaceWith(data['html']);
        $feedbackWrapper = $('#article-title-' + articleUid + '-translation-lang-' + langCode + '-feedback-wrapper');
    } else {
        //////// 通常の翻訳の作成・更新 //////
        var passageId = data['passage']['id'];
        // 編集ユーザーの編集フォームを閉じて、コンテンツを更新する。
        $('#passage-' + passageId + '-translation-lang-' + langCode + '-edit-form-uid-' + editorToken).replaceWith(data['html']);
        // 他の閲覧ユーザーのコンテンツを更新する。
        $('#passage-' + passageId + '-translation-lang-' + langCode).replaceWith(data['html']);
        $feedbackWrapper = $('#passage-' + passageId + '-translation-lang-' + langCode + '-feedback-wrapper');
    }
    // 編集者と閲覧者に、更新完了のフィードバックを伝える。
    displayFeedback($feedbackWrapper, message);
}


// 更新が成功したことを編集者と閲覧ユーザーに伝えるフィードバックを表示する。
// feedbackMessageを作成する。translationでもpassageでも同じ処理を利用する。
function displayFeedback($feedbackWrapper, message) {
    $feedbackWrapper.css({'opacity': '.2'}).animate({'opacity': '1'}, 500);
    $feedbackWrapper.css({'border-right': '1px double #2ECC71'});
    var $feedbackMessage = $feedbackWrapper.find('.feedback-message');
    $feedbackMessage.text(message);
    setTimeout(function () {
        $feedbackWrapper.css({'border-right': 'none'});
        $feedbackMessage.text('');
    }, 10000);
}