# frozen_string_literal: true
# Copyright 2025

class StatelessDemoController < ApplicationController
  # Demo data
  SAMPLE_PRODUCTS = [
    { id: 1, name: "iPhone 15 Pro", category: "electronics", brand: "apple", price: 999, color: "titanium" },
    { id: 2, name: "MacBook Air M2", category: "electronics", brand: "apple", price: 1199, color: "silver" },
    { id: 3, name: "AirPods Pro", category: "electronics", brand: "apple", price: 249, color: "white" },
    { id: 4, name: "Nike Air Max", category: "shoes", brand: "nike", price: 150, color: "black" },
    { id: 5, name: "Adidas Ultraboost", category: "shoes", brand: "adidas", price: 180, color: "white" },
    { id: 6, name: "Levi's 501", category: "clothing", brand: "levis", price: 89, color: "blue" },
    { id: 7, name: "Nike Hoodie", category: "clothing", brand: "nike", price: 75, color: "gray" },
    { id: 8, name: "Apple Watch", category: "electronics", brand: "apple", price: 399, color: "black" },
    { id: 9, name: "Converse Chuck Taylor", category: "shoes", brand: "converse", price: 65, color: "red" },
    { id: 10, name: "Columbia Jacket", category: "clothing", brand: "columbia", price: 120, color: "green" }
  ]
  
  def index
    # Handle filters from URL params
    @filters = params[:filters] || {}
    @products = filter_products(SAMPLE_PRODUCTS, @filters)
    
    # Handle pagination
    @page = (params[:page] || 1).to_i
    @per_page = 3
    @total_pages = (@products.count.to_f / @per_page).ceil
    @products = @products.slice((@page - 1) * @per_page, @per_page) || []
    
    # Handle search
    @search_query = params[:q]
    if @search_query.present?
      @search_results = search_products(SAMPLE_PRODUCTS, @search_query)
    end
    
    # Handle tabs
    @current_tab = params[:tab] || "products"
    
    # Handle modal
    @show_modal = params[:modal] == "info"
    
    # Filter options for the filter component
    @filter_options = {
      category: SAMPLE_PRODUCTS.map { |p| [p[:category], p[:category].capitalize] }.uniq.to_h,
      brand: SAMPLE_PRODUCTS.map { |p| [p[:brand], p[:brand].capitalize] }.uniq.to_h,
      color: SAMPLE_PRODUCTS.map { |p| [p[:color], p[:color].capitalize] }.uniq.to_h
    }
  end
  
  private
  
  def filter_products(products, filters)
    filtered = products.dup
    
    filters.each do |key, value|
      next if value.blank?
      filtered = filtered.select { |p| p[key.to_sym].to_s == value }
    end
    
    filtered
  end
  
  def search_products(products, query)
    return [] if query.blank?
    
    products.select do |product|
      product[:name].downcase.include?(query.downcase) ||
      product[:category].downcase.include?(query.downcase) ||
      product[:brand].downcase.include?(query.downcase)
    end.map do |product|
      {
        title: product[:name],
        description: "#{product[:brand].capitalize} - $#{product[:price]}",
        url: "#product-#{product[:id]}"
      }
    end
  end
end
# Copyright 2025
