class TitleModificationChannel < ApplicationCable::Channel
  def subscribed
    stream_from "title_modification_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
