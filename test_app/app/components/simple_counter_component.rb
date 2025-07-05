# frozen_string_literal: true

class SimpleCounterComponent < SwiftUIRails::Component::Base
  prop :count, type: Integer, default: 0
  
  swift_ui do
    text("Count: #{count}")
  end
end
# Copyright 2025
