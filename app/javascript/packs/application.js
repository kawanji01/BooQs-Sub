// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()
require("channels")
// jQueryの導入
require('jquery')
// bootstrap
//require("bootstrap")
//


// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

//= require jquery3
//= require popper
//= require bootstrap

import "./infinite-scroll_implementation"
import "./video"
import "./loading"
import "./web_speech_api"
// import "./youtube"



document.addEventListener("turbolinks:load", function() {
    // ローディング画面を表示する。
    var loadingShowBtns = document.querySelectorAll('.loading-show-btn');
    loadingShowBtns.forEach(function (item) {
        item.addEventListener('click', function() {
            item.nextElementSibling.classList.remove('is-hide');
        });
    });

    // layouts/application.html.erbに設置したローディング画面を表示する。
    var mainLoadingShowBtns = document.querySelectorAll('.main-loading-show-btn');
    mainLoadingShowBtns.forEach(function (item) {
        item.addEventListener('click', function() {
            var loading = document.querySelector('#loading');
            loading.classList.remove("is-hide");
        });
    });

    // フラッシュメッセージをクリックで消せるようにする。
    $(document).on("click", ".feedback_message .alert", function () {
        var $alert = $(this)
        if (!$alert.hasClass('not-remove')) {
            $alert.fadeOut().queue(function () {
                $alert.remove();
            });
        }
    });

});

