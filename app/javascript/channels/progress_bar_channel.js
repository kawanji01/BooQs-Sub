import consumer from "./consumer"

consumer.subscriptions.create("ProgressBarChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    var $article = $("#progress-bar-" + data['content_id'] + "-" + data['user_id']);
    if ($article.length !== 0) {
      var all_count = Number(data['all_count']);
      var process_count =  Number(data['process_count']);
      var progress = (process_count.toFixed(2) / all_count.toFixed(2)) * 100;
      $("#all-count").text(all_count);
      $("#process-count").text(process_count);
      $('#processing-progress-bar').css('width', Number(progress) + '%');

      if (all_count === process_count) {
        window.location.href = data['redirect_url'];
      }

    }
  }
});
