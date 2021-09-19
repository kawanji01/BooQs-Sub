class DownloadTranscriptionChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'download_transcription'
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
