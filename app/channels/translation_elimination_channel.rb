class TranslationEliminationChannel < ApplicationCable::Channel
  def subscribed
    stream_from "translation_elimination_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
