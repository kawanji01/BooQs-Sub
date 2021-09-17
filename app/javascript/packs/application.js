// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()
require("channels")


// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)
//= require jquery3
//= require popper
//= require bootstrap



document.addEventListener("turbolinks:load", function(){

    // ローディング画面を表示する。
    //$(document).on("click", ".loading-show-btn", function () {
    //    $(this).next('.loading').removeClass('is-hide');
        // スマホのキーボードを閉じる
    //    $(".text-input-form").blur();
    //});

    // layouts/application.html.erbに設置したローディング画面を表示する。
    var mainLoadingShowBtns = document.querySelectorAll('.main-loading-show-btn');
    mainLoadingShowBtns.forEach(function (item) {
        item.addEventListener('click', function() {
            var loading = document.querySelector('#loading');
            loading.classList.remove("is-hide");
        });
    });

});
