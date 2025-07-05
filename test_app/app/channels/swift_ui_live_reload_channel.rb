# frozen_string_literal: true

class SwiftUiLiveReloadChannel < ApplicationCable::Channel
  def subscribed
    # Only allow in development
    return reject unless Rails.env.development?
    
    stream_from "swift_ui_live_reload"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
# Copyright 2025
