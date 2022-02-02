import consumer from "./consumer"

consumer.subscriptions.create("TitleModificationChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    var $article = $('#article-' + data['article']['public_uid']);
    if ($article.length !== 0) {
      modifyTitle(data)
    }
  }
});

function modifyTitle(data) {
  var articleUid =  data['article']['public_uid'];
  // 編集ユーザーの編集フォームを閉じて、コンテンツを更新する。
  $('#article-title-' + articleUid + '-edit-form-uid-' + data['editor_token']).replaceWith(data['html']);
  // 他の閲覧ユーザーのコンテンツを更新する。
  $('#article-title-' + articleUid).replaceWith(data['html']);
  var $feedbackWrapper = $('#article-title-' + articleUid + '-feedback-wrapper');
  displayFeedback($feedbackWrapper, data['message']);
}

// 更新が成功したことを編集者と閲覧ユーザーに伝えるフィードバックを表示する。
// feedbackMessageを作成する。translationでもpassageでも同じ処理を利用する。
function displayFeedback($feedbackWrapper, message) {
  $feedbackWrapper.css({'opacity':'.2'}).animate({'opacity': '1'}, 1000);
  $feedbackWrapper.css({'border-right':'1px double','border-color':'#2ECC71'});
  var $feedbackMessage = $feedbackWrapper.find('.feedback-message');
  $feedbackMessage.text(message);
  setTimeout(function() {
    $feedbackMessage.css({'border-right':'none'});
    $feedbackMessage.text('');
  }, 10000);
}
