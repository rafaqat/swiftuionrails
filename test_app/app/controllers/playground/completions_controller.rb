# frozen_string_literal: true

class Playground::CompletionsController < ApplicationController
  
  def create
    context = params[:context] || ""
    position = params[:position] || {}
    cached_data = params[:cached_data] || {}
    
    service = Playground::CompletionService.new(context, position, cached_data)
    completions = service.generate_completions
    
    render json: { 
      suggestions: completions,
      version: Playground::DslRegistry.instance.version
    }
  end
end