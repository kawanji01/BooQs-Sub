
// articles/showのvideoで利用されるj
document.addEventListener("turbolinks:load", function () {


    /* videoの途中固定 */
    if ($('#movie-wrap').length) {

        $(function () {
            //var $body = $('body'),
            var $video = $('#movie-wrap'),
                videoOffsetTop = $video.offset().top,
                videoHeight = $video.height(),
                $padding = $('#auto-scroll-padding'),
                $sidebar = $('#mb-sidebar');


            $(window).on('scroll', function () {
                var $grid = $sidebar.parent();
                if ($(this).scrollTop() > videoOffsetTop) {
                    $video.addClass('is-fixed');
                    if ($grid.hasClass('col-xl-3')) {
                        $grid.removeClass('col-xl-3');
                        $grid.addClass('col-xl-9');
                        $sidebar.addClass('style-reset');
                    }
                    //$sidebar.addClass('hidden');
                    $padding.height(videoHeight);
                } else {
                    $video.removeClass('is-fixed');
                    if ($grid.hasClass('col-xl-9')) {
                        $grid.removeClass('col-xl-9');
                        $sidebar.removeClass('style-reset');
                        $grid.addClass('col-xl-3');
                    }
                    //$sidebar.removeClass('hidden');
                    $padding.height(0);
                }
            });
        });

    }




    /* position: stickyを利用して、メインカラムに動画を表示する場合の処理
    /* 却下した理由： issue #1296を参照
    ・画面が狭くなり、メインコンテンツである文章が読みにくくなる。
    ・画面が狭くなることで、文字起こしや翻訳の修正が難しくなる。
    BooQsのメインコンテンツは文章と辞書なので、動画によってメインコンテンツが邪魔されるのは望ましくない。
     */
    /*
   if ($('#movie-wrap').length) {
       $(function () {
           //var $body = $('body'),
           var $video = $('#movie-wrap'),
               videoOffsetTop = $video.offset().top,
               videoHeight = $video.height(),
               $padding = $('#auto-scroll-padding'),
               $sidebar = $('#mb-sidebar');


           $(window).on('scroll', function () {
               var $grid = $sidebar.parent();
               if ($(this).scrollTop() > videoOffsetTop) {
                   $video.addClass('is-sticky');
                   $padding.height(videoHeight);
               } else {
                   $video.removeClass('is-sticky');
                   $padding.height(0);
               }
           });
       });

       // position: stickyを機能させるために、先祖要素のすべてのoverflowをvisibleにする。
       $('#movie-wrap').parents('*').css(
           {'overflow' : 'visible', 'overflow-x' : 'visible', 'overflow-y' : 'visible'}
       );

   }

    */


    // 最上部に移動
    $(document).on("click", "#scrollTop", function () {
        $('body,html').animate({ scrollTop: 0 }, 500);
        // 画面遷移をキャンセルする
        return false;
    })

    // 最下部に移動
    $(document).on("click", "#scrollBottom", function () {
        var position = $('#related-contents').offset().top;
        $('body,html').animate({ scrollTop: position }, 500);
        // 画面遷移をキャンセルする
        return false;
    })

    // テキストプレビュー
    $(document).on('click', '.text-preview-btn', function () {
        var $this = $(this);
        var $wrapper = $this.parents('.text-preview-wrapper');
        $("#main").nextAll('#loading').removeClass('is-hide');
        var targetText = $wrapper.find('.preview-target-text').val();
        var targetLangNumber = $wrapper.find('.preview-target-lang-number').val();
        $.get("/preview", { text: targetText, lang_number: targetLangNumber } );
        // 画面遷移をキャンセルする
        return false;
    });



    // ビデオの表示・非表示のトグル
    $(document).off('click', '#video-display-toggle');
    $(document).on('click', '#video-display-toggle', function () {
        var $this = $(this);
        var $video = $('#youtube-video');
        if ($video.is(':visible')) {
            $this.html('<i class="fas fa-eye"></i>')
            //$video.addClass('d-none');
            $video.slideUp();
        } else {
            // 表示
            $this.html('<i class="fas fa-eye-slash"></i>')
            //$video.removeClass('d-none');
            $video.slideDown();
        }

    });



});