class AlignmentTestController < ApplicationController
  def index
    render AlignmentTestComponent.new
  end
end