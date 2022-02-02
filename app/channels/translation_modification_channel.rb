class TranslationModificationChannel < ApplicationCable::Channel
  def subscribed
    stream_from "translation_modification_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
