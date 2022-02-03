class PassageEliminationChannel < ApplicationCable::Channel
  def subscribed
    stream_from "passage_elimination_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
