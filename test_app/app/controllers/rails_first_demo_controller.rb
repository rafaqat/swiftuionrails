# Copyright 2025
class RailsFirstDemoController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :increment_counter, :add_todo, :delete_todo, :search ]

  def index
    # Initialize demo data in session
    session[:demo_counter] ||= 0
    session[:demo_todos] ||= [
      { id: 1, text: "Learn Rails-first patterns", completed: true },
      { id: 2, text: "Build with Turbo and Stimulus", completed: false }
    ]
    session[:demo_products] ||= [
      { id: 1, name: "Ruby on Rails Book", price: 29.99, category: "books" },
      { id: 2, name: "Rails T-Shirt", price: 19.99, category: "apparel" },
      { id: 3, name: "Rails Course", price: 99.99, category: "courses" },
      { id: 4, name: "Rails Sticker Pack", price: 9.99, category: "accessories" },
      { id: 5, name: "Advanced Rails Book", price: 39.99, category: "books" }
    ]

    @counter = session[:demo_counter]
    @todos = session[:demo_todos]
    @products = filter_products(session[:demo_products], params[:search], params[:category])
    @search_query = params[:search] || ""
    @selected_category = params[:category] || "all"
  end

  def increment_counter
    session[:demo_counter] = (session[:demo_counter] || 0) + 1
    @counter = session[:demo_counter]

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("rails-counter", partial: "rails_first_demo/counter", locals: { counter: @counter }) }
      format.html { redirect_to rails_first_demo_path }
    end
  end

  def add_todo
    todos = session[:demo_todos] || []
    new_todo = {
      id: Time.now.to_i,
      text: params[:todo_text],
      completed: false
    }
    todos << new_todo
    session[:demo_todos] = todos
    @todos = todos

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("rails-todos", partial: "rails_first_demo/todos", locals: { todos: @todos }),
          turbo_stream.replace("todo-form", partial: "rails_first_demo/todo_form")
        ]
      end
      format.html { redirect_to rails_first_demo_path }
    end
  end

  def delete_todo
    todos = session[:demo_todos] || []
    todos.reject! { |todo| todo[:id] == params[:id].to_i }
    session[:demo_todos] = todos
    @todos = todos

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("rails-todos", partial: "rails_first_demo/todos", locals: { todos: @todos }) }
      format.html { redirect_to rails_first_demo_path }
    end
  end

  def search
    @products = filter_products(session[:demo_products], params[:search], params[:category])
    @search_query = params[:search] || ""
    @selected_category = params[:category] || "all"

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("rails-products", partial: "rails_first_demo/products", locals: { products: @products, search_query: @search_query, selected_category: @selected_category }) }
      format.html { redirect_to rails_first_demo_path(search: @search_query, category: @selected_category) }
    end
  end

  private

  def filter_products(products, search_query, category)
    filtered = products || []

    if search_query.present?
      filtered = filtered.select { |p| p[:name].downcase.include?(search_query.downcase) }
    end

    if category.present? && category != "all"
      filtered = filtered.select { |p| p[:category] == category }
    end

    filtered
  end
end
# Copyright 2025
