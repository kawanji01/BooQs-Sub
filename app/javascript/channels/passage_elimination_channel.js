import consumer from "./consumer"

consumer.subscriptions.create("PassageEliminationChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    var $article = $("#article-" + data['article']['public_uid']);
    if ($article.length !== 0) {
      eliminatePassage(data, $article);
    }
  }
});



function eliminatePassage(data, $article) {
  var passageId = data['passage']['id'];
  var editorToken = data['editor_token'];
  // 編集フォームを閉じる。
  var $form = $('#passage-' + passageId + '-edit-form-uid-' + editorToken);
  if ($form.length) {
    // bootstrapのモーダルを閉じる
    $('body').removeClass('modal-open');
    $('.modal-backdrop').remove();
  }
  // フィードバックラッパーの親を消すことで、編集ユーザーと閲覧ユーザーのどちらのpassageも消す。
  var $passage = $('#passage-' + passageId + '-feedback-wrapper').parent()
  $passage.show().fadeOut(1000).queue(function () {
    $passage.remove();
  });

}