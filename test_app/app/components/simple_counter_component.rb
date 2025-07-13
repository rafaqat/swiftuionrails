# frozen_string_literal: true

# Copyright 2025

class SimpleCounterComponent < ApplicationComponent
  prop :count, type: Integer, default: 0

  swift_ui do
    text("Count: #{count}")
  end
end
# Copyright 2025
