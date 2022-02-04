
///////////    WebSpeechAPIによる読み上げ   ////////////////
// 読み上げに関わるほかの処理は、javascripts/answer.js.erbのfetchLangVariable、


// ブラウザによっては、初回読み込み時に空要素を返してくる場合がある。そのため、事前に一度voicesを読み込んでおく。
speechSynthesis.getVoices()

// iOSの場合、一度ユーザーの操作によって音を発生させない限り、システム側で音を鳴らすことはできない。https://qiita.com/pentamania/items/2c568a9ec52148bbfd08
//$(document).on("click", ".audio-btn-silence", function () {
//    var sound = new Howl({src: ['https://s3-ap-northeast-1.amazonaws.com/kawanji/assets/audio/silence.mp3']});
//    sound.play()
//});


$(document).on("click", ".speech-btn-nil", function () {
    // WebSpeechAPIでブラウザがクラッシュする問題（https://developer.apple.com/forums/thread/671863 ）の解決策としてGCPのTTSを利用する場合、
    // 以下をすべてコメントアウトする。


    // unsupported.

    if (!'SpeechSynthesisUtterance' in window) {
        alert('Speech synthesis(音声合成) APIには未対応です.');
        return;
    }
    //speechSynthesis.cancel();

    // 発話機能をインスタンス化
    var msg = new SpeechSynthesisUtterance();
    var voice = speechSynthesis.getVoices().find(function(voice){
        return voice.lang === 'en-US';
    });
    msg.voice  = voice;

    msg.lang   = 'en-US'; // en-US or ja-JP
    msg.volume = 0; // 音量 min 0 ~ max 1 （音量なし）
    msg.rate   = 1.0; // 速度 min 0 ~ max 10
    msg.pitch  = 1.0; // 音程 min 0 ~ max 2


    msg.text = "a"; // 喋る内容

    // 発話実行
    speechSynthesis.speak(msg);

    // 終了時の処理
    //msg.onend = function (event) {
    //    console.log('喋った時間：' + event.elapsedTime + 's');
    //    console.log(msg.lang + msg.voice);
    //}


});


// Base64 → BlobUrl
function base64ToBlobUrl(base64) {
    var bin = atob(base64.replace(/^.*,/, ''))
    var buffer = new Uint8Array(bin.length)
    for (var i = 0; i < bin.length; i++) {
        buffer[i] = bin.charCodeAt(i)
    }
    return window.URL.createObjectURL(new Blob([buffer.buffer], {type: "audio/wav"}))
}


//英語
//音声の種類の確認：https://mseeeen.msen.jp/list-voices-with-web-speech-synthesis-api/
//ブラウザ対応のvoice確認：https://developer.mozilla.org/en-US/docs/Web/API/SpeechSynthesis/getVoices
$(document).on("click", ".speech-btn-en", function () {



    // unsupported.

    if (!'SpeechSynthesisUtterance' in window) {
        alert('Speech synthesis(音声合成) APIには未対応です.');
        return;
    }
    speechSynthesis.cancel();

    // 発話機能をインスタンス化
    var msg = new SpeechSynthesisUtterance();

    var voice = speechSynthesis.getVoices().find(function (voice) {
        //return /Samantha/.test(voice.voiceURI);
        return voice.name === "Samantha"
    });


    msg.voice = voice;

    msg.lang = 'en-US'; // en-US or ja-JP
    msg.volume = 1.0; // 音量 min 0 ~ max 1
    msg.rate = 1.0; // 速度 min 0 ~ max 10
    msg.pitch = 1.0; // 音程 min 0 ~ max 2

    msg.text = $(this).prev('.speech-text').text(); // 喋る内容

    // 発話実行
    speechSynthesis.speak(msg);





});

//日本語
$(document).on("click", ".speech-btn-ja", function () {
    // unsupported.
    if (!'SpeechSynthesisUtterance' in window) {
        alert('Speech synthesis(音声合成) APIには未対応です.');
        return;
    }
    // 読み上げるには一度キャンセルが必要。
    speechSynthesis.cancel();

    // 発話機能をインスタンス化
    var msg = new SpeechSynthesisUtterance();
    var voice = speechSynthesis.getVoices().find(function (voice) {
        return voice.lang === 'ja-JP';
    });
    msg.voice = voice;

    msg.lang = 'ja-JP';
    msg.volume = 1.0; // 音量 min 0 ~ max 1
    msg.rate = 1.0; // 速度 min 0 ~ max 10
    msg.pitch = 1.0; // 音程 min 0 ~ max 2


    msg.text = $(this).prev('.speech-text').text(); // 喋る内容

    // 発話実行
    speechSynthesis.speak(msg);

});


//中国語（簡体字）
$(document).on("click", ".speech-btn-ch", function () {
    // unsupported.
    if (!'SpeechSynthesisUtterance' in window) {
        alert('Speech synthesis(音声合成) APIには未対応です.');
        return;
    }
    speechSynthesis.cancel();

    // 発話機能をインスタンス化
    var msg = new SpeechSynthesisUtterance();
    var voice = speechSynthesis.getVoices().find(function (voice) {
        return voice.lang === 'zh-CN';
    });
    msg.voice = voice;

    msg.lang = 'zh-CN'; // en-US or ja-JP
    msg.volume = 1.0; // 音量 min 0 ~ max 1
    msg.rate = 1.0; // 速度 min 0 ~ max 10
    msg.pitch = 1.0; // 音程 min 0 ~ max 2


    msg.text = $(this).prev('.speech-text').text(); // 喋る内容

    // 発話実行
    speechSynthesis.speak(msg);

    // 終了時の処理
    //msg.onend = function (event) {
    //    console.log('喋った時間：' + event.elapsedTime + 's');
    //    console.log(msg.lang + msg.voice);
    //}

});

//中国語（繁体字）
$(document).on("click", ".speech-btn-tw", function () {
    // unsupported.
    if (!'SpeechSynthesisUtterance' in window) {
        alert('Speech synthesis(音声合成) APIには未対応です.');
        return;
    }
    speechSynthesis.cancel();

    // 発話機能をインスタンス化
    var msg = new SpeechSynthesisUtterance();
    var voice = speechSynthesis.getVoices().find(function (voice) {
        return voice.lang === 'zh-TW';
    });
    msg.voice = voice;

    msg.lang = 'zh-TW'; // en-US or ja-JP
    msg.volume = 1.0; // 音量 min 0 ~ max 1
    msg.rate = 1.0; // 速度 min 0 ~ max 10
    msg.pitch = 1.0; // 音程 min 0 ~ max 2


    msg.text = $(this).prev('.speech-text').text(); // 喋る内容

    // 発話実行
    speechSynthesis.speak(msg);

    // 終了時の処理
    //msg.onend = function (event) {
    //    console.log('喋った時間：' + event.elapsedTime + 's');
    //    console.log(msg.lang + msg.voice);
    //}

});

//韓国語
$(document).on("click", ".speech-btn-kr", function () {
    // unsupported.
    if (!'SpeechSynthesisUtterance' in window) {
        alert('Speech synthesis(音声合成) APIには未対応です.');
        return;
    }

    speechSynthesis.cancel();

    // 発話機能をインスタンス化
    var msg = new SpeechSynthesisUtterance();
    var voice = speechSynthesis.getVoices().find(function (voice) {
        return voice.lang === 'ko-KR';
    });
    msg.voice = voice;
    msg.lang = 'ko-KR'; // en-US or ja-JP
    msg.volume = 1.0; // 音量 min 0 ~ max 1
    msg.rate = 1.0; // 速度 min 0 ~ max 10
    msg.pitch = 1.0; // 音程 min 0 ~ max 2


    msg.text = $(this).prev('.speech-text').text(); // 喋る内容

    // 発話実行
    speechSynthesis.speak(msg);

    // 終了時の処理
    //msg.onend = function (event) {
    //    console.log('喋った時間：' + event.elapsedTime + 's');
    //    console.log(msg.lang + msg.voice);
    //}

});


//フランス語
$(document).on("click", ".speech-btn-fr", function () {
    // unsupported.
    if (!'SpeechSynthesisUtterance' in window) {
        alert('Speech synthesis(音声合成) APIには未対応です.');
        return;
    }
    speechSynthesis.cancel();


    // 発話機能をインスタンス化
    var msg = new SpeechSynthesisUtterance();
    var voice = speechSynthesis.getVoices().find(function (voice) {
        return voice.lang === 'fr-FR';
    });
    msg.voice = voice;


    msg.lang = 'fr-FR'; // en-US or ja-JP
    msg.volume = 1.0; // 音量 min 0 ~ max 1
    msg.rate = 1.0; // 速度 min 0 ~ max 10
    msg.pitch = 1.0; // 音程 min 0 ~ max 2


    msg.text = $(this).prev('.speech-text').text(); // 喋る内容

    // 発話実行
    speechSynthesis.speak(msg);

    // 終了時の処理
    //msg.onend = function (event) {
    //    console.log('喋った時間：' + event.elapsedTime + 's');
    //    console.log(msg.lang + msg.voice);
    //}

});


//スペイン語
$(document).on("click", ".speech-btn-es", function () {
    // unsupported.
    if (!'SpeechSynthesisUtterance' in window) {
        alert('Speech synthesis(音声合成) APIには未対応です.');
        return;
    }
    speechSynthesis.cancel();

    // 発話機能をインスタンス化
    var msg = new SpeechSynthesisUtterance();
    var voice = speechSynthesis.getVoices().find(function (voice) {
        return voice.lang === 'es-ES';
    });
    msg.voice = voice;


    msg.lang = 'es-ES'; // en-US or ja-JP
    msg.volume = 1.0; // 音量 min 0 ~ max 1
    msg.rate = 1.0; // 速度 min 0 ~ max 10
    msg.pitch = 1.0; // 音程 min 0 ~ max 2


    msg.text = $(this).prev('.speech-text').text(); // 喋る内容

    // 発話実行
    speechSynthesis.speak(msg);

    // 終了時の処理
    //msg.onend = function (event) {
    //    console.log('喋った時間：' + event.elapsedTime + 's');
    //    console.log(msg.lang + msg.voice);
    //}

});




//ロシア語
$(document).on("click", ".speech-btn-ru", function () {
    // unsupported.
    if (!'SpeechSynthesisUtterance' in window) {
        alert('Speech synthesis(音声合成) APIには未対応です.');
        return;
    }

    speechSynthesis.cancel();

    // 発話機能をインスタンス化
    var msg = new SpeechSynthesisUtterance();
    var voice = speechSynthesis.getVoices().find(function (voice) {
        return voice.lang === 'ru-RU';
    });
    msg.voice = voice;


    msg.lang = 'ru-RU'; // en-US or ja-JP
    msg.volume = 1.0; // 音量 min 0 ~ max 1
    msg.rate = 1.0; // 速度 min 0 ~ max 10
    msg.pitch = 1.0; // 音程 min 0 ~ max 2


    msg.text = $(this).prevAll('.speech-text').text(); // 喋る内容

    // 発話実行
    speechSynthesis.speak(msg);

    // 終了時の処理
    //msg.onend = function (event) {
    //    console.log('喋った時間：' + event.elapsedTime + 's');
    //    console.log(msg.lang + msg.voice);
    //}

});

//ドイツ語
$(document).on("click", ".speech-btn-de", function () {
    // unsupported.
    if (!'SpeechSynthesisUtterance' in window) {
        alert('Speech synthesis(音声合成) APIには未対応です.');
        return;
    }

    speechSynthesis.cancel();

    // 発話機能をインスタンス化
    var msg = new SpeechSynthesisUtterance();
    var voice = speechSynthesis.getVoices().find(function (voice) {
        return voice.lang === 'de-DE';
    });
    msg.voice = voice;

    msg.lang = 'de-DE'; // en-US or ja-JP
    msg.volume = 1.0; // 音量 min 0 ~ max 1
    msg.rate = 1.0; // 速度 min 0 ~ max 10
    msg.pitch = 1.0; // 音程 min 0 ~ max 2
    msg.text = $(this).prevAll('.speech-text').text(); // 喋る内容

    // 発話実行
    speechSynthesis.speak(msg);

    // 終了時の処理
    //msg.onend = function (event) {
    //    console.log('喋った時間：' + event.elapsedTime + 's');
    //    console.log(msg.lang + msg.voice);
    //}

});


//イタリア語
$(document).on("click", ".speech-btn-it", function () {
    // unsupported.
    if (!'SpeechSynthesisUtterance' in window) {
        alert('Speech synthesis(音声合成) APIには未対応です.');
        return;
    }

    speechSynthesis.cancel();

    // 発話機能をインスタンス化
    var msg = new SpeechSynthesisUtterance();
    var voice = speechSynthesis.getVoices().find(function (voice) {
        return voice.lang === 'it-IT';
    });
    msg.voice = voice;

    msg.lang = 'it-IT'; // en-US or ja-JP
    msg.volume = 1.0; // 音量 min 0 ~ max 1
    msg.rate = 1.0; // 速度 min 0 ~ max 10
    msg.pitch = 1.0; // 音程 min 0 ~ max 2


    msg.text = $(this).prevAll('.speech-text').text(); // 喋る内容

    // 発話実行
    speechSynthesis.speak(msg);

    // 終了時の処理
    //msg.onend = function (event) {
    //    console.log('喋った時間：' + event.elapsedTime + 's');
    //    console.log(msg.lang + msg.voice);
    //}

});


//タイ語
$(document).on("click", ".speech-btn-th", function () {
    // unsupported.
    if (!'SpeechSynthesisUtterance' in window) {
        alert('Speech synthesis(音声合成) APIには未対応です.');
        return;
    }

    speechSynthesis.cancel();

    // 発話機能をインスタンス化
    var msg = new SpeechSynthesisUtterance();
    var voice = speechSynthesis.getVoices().find(function (voice) {
        return voice.lang === 'th-TH';
    });
    msg.voice = voice;

    msg.lang = 'th-TH'; // en-US or ja-JP
    msg.volume = 1.0; // 音量 min 0 ~ max 1
    msg.rate = 1.0; // 速度 min 0 ~ max 10
    msg.pitch = 1.0; // 音程 min 0 ~ max 2


    msg.text = $(this).prevAll('.speech-text').text(); // 喋る内容

    // 発話実行
    speechSynthesis.speak(msg);

    // 終了時の処理
    //msg.onend = function (event) {
    //    console.log('喋った時間：' + event.elapsedTime + 's');
    //    console.log(msg.lang + msg.voice);
    //}

});


//インドネシア語
$(document).on("click", ".speech-btn-id", function () {
    // unsupported.
    if (!'SpeechSynthesisUtterance' in window) {
        alert('Speech synthesis(音声合成) APIには未対応です.');
        return;
    }

    speechSynthesis.cancel();

    // 発話機能をインスタンス化
    var msg = new SpeechSynthesisUtterance();
    var voice = speechSynthesis.getVoices().find(function (voice) {
        return voice.lang === 'id-ID';
    });
    msg.voice = voice;

    msg.lang = 'id-ID'; // en-US or ja-JP
    msg.volume = 1.0; // 音量 min 0 ~ max 1
    msg.rate = 1.0; // 速度 min 0 ~ max 10
    msg.pitch = 1.0; // 音程 min 0 ~ max 2


    msg.text = $(this).prevAll('.speech-text').text(); // 喋る内容

    // 発話実行
    speechSynthesis.speak(msg);

    // 終了時の処理
    //msg.onend = function (event) {
    //    console.log('喋った時間：' + event.elapsedTime + 's');
    //    console.log(msg.lang + msg.voice);
    //}

});

