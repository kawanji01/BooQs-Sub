import consumer from "./consumer"

consumer.subscriptions.create("DownloadFileChannel", {
    connected() {
        // Called when the subscription is ready for use on the server
    },

    disconnected() {
        // Called when the subscription has been terminated by the server
    },

    received(data) {
        // Called when there's incoming data on the websocket for this channel
        var captionsModalWrapper = document.querySelector(`#captions-${data['token']}`);
        if (!captionsModalWrapper) {
            return;
        }

        completeCaptionDownload(captionsModalWrapper, data['message']);
        downloadCaptionSRT(data['srt']);
        downloadCaptionCSV(data['csv']);
        downloadCaptionTXT(data['txt']);

        function completeCaptionDownload(modal, message) {
            const title = modal.querySelector('#modal-title');
            title.textContent = message;
            modal.querySelector('#contents-form').innerHTML = `
<a id="download-srt-btn"><div class="btn btn-lg btn-info w-100 mb-3 mt-5 font-weight-bold">Download SRT</div></a>
<a id="download-txt-btn"><div class="btn btn-lg btn-info w-100 my-3 font-weight-bold">Download TXT</div></a>
<a id="download-csv-btn"><div class="btn btn-lg btn-info w-100 my-3 font-weight-bold">Download CSV</div></a>`;
        }

        function downloadCaptionSRT(content) {
            // 参照： https://chaika.hatenablog.com/entry/2018/12/23/090000
            const blob = new Blob([ content ], { "type" : "text/plain" });
            const a = document.querySelector('#download-srt-btn');
            a.download = 'caption.srt.txt';
            a.href = window.URL.createObjectURL(blob);
        }

        function downloadCaptionCSV(content) {
            // CSVのダウンロード処理：参考：https://qiita.com/wadahiro/items/eb50ac6bbe2e18cf8813
            const bom = new Uint8Array([0xEF, 0xBB, 0xBF]);
            const blob = new Blob([bom, content], {"type": "text/csv"});
            const a = document.querySelector('#download-csv-btn');
            a.download = 'caption.csv';
            a.href = window.URL.createObjectURL(blob);
        }

        function downloadCaptionTXT(content) {
            const blob = new Blob([ content ], { "type" : "text/plain" });
            //const a = document.createElement('a');
            const a = document.querySelector('#download-txt-btn');
            a.download = 'caption.txt';
            a.href = window.URL.createObjectURL(blob);
        }

    }
});
