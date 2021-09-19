import consumer from "./consumer"

consumer.subscriptions.create("DownloadTranscriptionChannel", {
    connected() {
        // Called when the subscription is ready for use on the server
    },

    disconnected() {
        // Called when the subscription has been terminated by the server
    },

    received(data) {
        // Called when there's incoming data on the websocket for this channel
        var speechToTextModalWrapper = document.querySelector('#speech-to-text-' + data['token']);
        console.log('speech-to-text');
        if (!speechToTextModalWrapper) {
            return;
        }
        document.querySelector('#all-count').textContent = '100';
        var processCount = Number(data['process_count']);
        // var progress = (processCount.toFixed(2) / processCount.toFixed(2)) * 100;
        //$("#process-count").text(process_count);
        document.querySelector('#process-count').textContent = data['process_count'];
        //$('#processing-progress-bar').css('width', processCount + '%');
        document.querySelector('#processing-progress-bar').style.width = `${processCount}%`;

        if (processCount !== 100) {
            return;
        }

        completeDownload(speechToTextModalWrapper, data['message']);
        downloadSRT(data['srt']);
        downloadCSV(data['csv']);
        downloadTXT(data['txt']);

        function completeDownload(modal, message) {
            const title = modal.querySelector('#modal-title');
            title.textContent = message;
            const progressBar = document.querySelector('#download-progress-bar');
            progressBar.innerHTML = ``
            document.querySelector('#contents-form').innerHTML = `
<a id="download-srt-btn"><div class="btn btn-lg btn-info w-100 mb-3 mt-5 font-weight-bold">Download SRT</div></a>
<a id="download-txt-btn"><div class="btn btn-lg btn-info w-100 my-3 font-weight-bold">Download TXT</div></a>
<a id="download-csv-btn"><div class="btn btn-lg btn-info w-100 my-3 font-weight-bold">Download CSV</div></a>`;

        }

        function downloadSRT(content) {
            // 参照： https://chaika.hatenablog.com/entry/2018/12/23/090000
            const blob = new Blob([ content ], { "type" : "text/plain" });
            const a = document.querySelector('#download-srt-btn');
            a.download = 'transcription.srt';
            a.href = window.URL.createObjectURL(blob);
            //a.click();
        }

        function downloadCSV(content) {
            // CSVのダウンロード処理：参考：https://qiita.com/wadahiro/items/eb50ac6bbe2e18cf8813
            const bom = new Uint8Array([0xEF, 0xBB, 0xBF]);
            const blob = new Blob([bom, content], {"type": "text/csv"});
            const a = document.querySelector('#download-csv-btn');
            a.download = 'transcription.csv';
            a.href = window.URL.createObjectURL(blob);
            //a.click();
        }

        function downloadTXT(content) {
            const blob = new Blob([ content ], { "type" : "text/plain" });
            //const a = document.createElement('a');
            const a = document.querySelector('#download-txt-btn');
            a.download = 'transcription.txt';
            a.href = window.URL.createObjectURL(blob);
            //a.click();
        }




    }

});
