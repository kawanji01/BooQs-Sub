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
        let modal = document.querySelector(`#captions-${data['token']}`);
        if (!modal) {
            return;
        }

        switch (data['file_type']) {
            case 'csv':
                downloadCSV(data['file']);
                break;
            case 'srt':
                downloadSRT(data['file']);
                break;
            case 'txt':
                downloadTXT(data['file']);
                break;
        }
        completeDownload(modal, data['message']);


        function downloadSRT(content) {
            // 参照： https://chaika.hatenablog.com/entry/2018/12/23/090000
            const blob = new Blob([ content ], { "type" : "text/plain" });
            const a = document.createElement('a');
            a.download = 'subtitle.srt';
            a.href = window.URL.createObjectURL(blob);
            a.click();
        }

        function downloadCSV(content) {
            // CSVのダウンロード処理：参考：https://qiita.com/wadahiro/items/eb50ac6bbe2e18cf8813
            const bom = new Uint8Array([0xEF, 0xBB, 0xBF]);
            const blob = new Blob([bom, content], {"type": "text/csv"});
            const a = document.createElement('a');
            a.download = 'subtitle.csv';
            a.href = window.URL.createObjectURL(blob);
            a.click();
        }

        function downloadTXT(content) {
            const blob = new Blob([ content ], { "type" : "text/plain" });
            const a = document.createElement('a');
            a.download = 'subtitle.txt';
            a.href = window.URL.createObjectURL(blob);
            a.click();
        }

        function completeDownload(modal, message) {
            const title = modal.querySelector('#modal-title');
            title.textContent = message;
            const progressBar = document.querySelector('#download-progress-bar');
            progressBar.innerHTML = ``
        }

    }
});
