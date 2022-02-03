# frozen_string_literal: true

# Passage（source text）'s edit and creation
class PassageModificationChannel < ApplicationCable::Channel
  def subscribed
    stream_from "passage_modification_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
