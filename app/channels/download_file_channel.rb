class DownloadFileChannel < ApplicationCable::Channel
  def subscribed
    stream_from "download_file_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
