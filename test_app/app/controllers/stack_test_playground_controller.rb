class StackTestPlaygroundController < ApplicationController
  def index
    render StackTestPlaygroundComponent.new
  end
end