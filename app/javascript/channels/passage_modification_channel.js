import consumer from "./consumer"

consumer.subscriptions.create("PassageModificationChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    var $article = $("#article-" + data['article']['public_uid']);
    if ($article.length !== 0) {
      modifyPassage(data, $article)
    }
  }
});


function modifyPassage(data, $article) {
  var passage = data['passage']
  var passageId = passage['id'];
  var message = data['message'];
  var editorToken = data['editor_token'];

  // 編集者のフォームを消して更新する
  $('#passage-' + passageId + '-edit-form-uid-' + editorToken).replaceWith(data['html']);
  // 閲覧者の原文を更新する
  $('#passage-' + passageId).replaceWith(data['html']);

  // 更新したpassageを再生箇所に移動させる。
  var startTime = passage['start_time'];
  movePassage(passageId, startTime);

  // 編集者と閲覧者に、更新完了のフィードバックを伝える。
  var $feedbackWrapper = $('#passage-' + passageId + '-feedback-wrapper');
  displayPassageFeedback($feedbackWrapper, message);
}

// 更新したpassageを再生箇所に移動させる処理
function movePassage(passageId, startTime) {
  var updatedPassage = $('#passage-' + passageId);
  var $passages = $('#passages-and-translations').find('.passage-component');
  // 作成したpassageよりも前に再生されるpassageをすべて取得する。
  var readingPassage = $passages.filter(function () {
    return $(this).data('start') < startTime
  })

  // 前に再生されるpassageがないということは、作成したpassageが最初ということなので先頭に挿入する。
  if (readingPassage.length === 0 || $passages.length === 0) {
    //console.log('一番最初に挿入');
    updatedPassage.prependTo('#passage-list-wrapper');
  } else {
    // 前に再生されるpassageのラストに挿入すればちょうど良い場所に挿入される。
    //console.log('途中かラストに挿入');
    var previousPassage = readingPassage.last();
    updatedPassage.insertAfter(previousPassage);
  }
}


// 更新が成功したことを編集者と閲覧ユーザーに伝えるフィードバックを表示する。
function displayPassageFeedback($feedbackWrapper, message) {
  $feedbackWrapper.css({'opacity': '.2'}).animate({'opacity': '1'}, 500);
  $feedbackWrapper.css({'border-right': '1px double #2ECC71'});
  var $feedbackMessage = $feedbackWrapper.find('.passage-feedback-message');
  $feedbackMessage.text(message);
  setTimeout(function () {
    $feedbackWrapper.css({'border-right': 'none'});
    $feedbackMessage.text('');
  }, 10000);
}
