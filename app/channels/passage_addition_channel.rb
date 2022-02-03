class PassageAdditionChannel < ApplicationCable::Channel
  def subscribed
    stream_from "passage_addition_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
