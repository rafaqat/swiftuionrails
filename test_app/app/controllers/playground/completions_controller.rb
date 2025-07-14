# frozen_string_literal: true

class Playground::CompletionsController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def create
    context = params[:context] || ""
    position = params[:position] || {}
    
    service = Playground::CompletionService.new(context, position)
    completions = service.generate_completions
    
    render json: { 
      suggestions: completions,
      version: Playground::DslRegistry.instance.version
    }
  end
end