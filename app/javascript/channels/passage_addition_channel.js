import consumer from "./consumer"

consumer.subscriptions.create("PassageAdditionChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    var $article = $("#article-" + data['article']['public_uid']);
    if ($article.length !== 0) {
      addPassage(data, $article)
    }
  }
});


function addPassage(data, $article) {
  var passage = data['passage'];
  var editorToken = data['editor_token'];
  var message = data['message'];
  // 編集フォームを削除する
  $('#new-passage-form-uid-'+ editorToken).remove();

  // youtube.jsと同じような処理で、新しく作成されたpassageを差し込む位置を計算する。
  var $passages = $('#passages-and-translations').find('.passage-component');
  var startTime = passage['start_time']
  // var end_time = data['passage']['end_time']

  // 作成したpassageよりも前に再生されるpassageをすべて取得する。
  var readingPassage = $passages.filter(function () {
    return $(this).data('start') < startTime
  })

  // 前に再生されるpassageがないということは、作成したpassageが最初ということなので先頭に挿入する。
  if (readingPassage.length === 0 || $passages.length === 0) {
    //console.log('一番最初に挿入');
    $('#passage-list-wrapper').prepend(data['html']);
  } else {
    // 前に再生されるpassageのラストに挿入すればちょうど良い場所に挿入される。
    //console.log('途中かラストに挿入');
    var previousPassage = readingPassage.last()
    previousPassage.after(data['html']);
  }
  var $feedbackWrapper = $('#passage-' + passage['id'] + '-feedback-wrapper');
  displayPassageFeedback($feedbackWrapper, message);
}


// 更新が成功したことを編集者と閲覧ユーザーに伝えるフィードバックを表示する。
// feedbackMessageを作成する。translationでもpassageでも同じ処理を利用する。
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

