# frozen_string_literal: true

require 'test_helper'

class PlaygroundDataCompressionTest < ActionDispatch::IntegrationTest
  test "compressed data files are generated correctly" do
    # Check that original files exist
    original_files = %w[tailwind_colors.json spacing_values.json font_sizes.json completion_data.json]
    
    original_files.each do |filename|
      path = Rails.root.join("public/playground/data", filename)
      assert File.exist?(path), "Original file #{filename} should exist"
    end
    
    # Check that compressed files exist
    original_files.each do |filename|
      compressed_path = Rails.root.join("public/playground/data", filename.gsub('.json', '.json.gz'))
      base64_path = Rails.root.join("public/playground/data", filename.gsub('.json', '.json.b64'))
      
      assert File.exist?(compressed_path), "Compressed file #{filename}.gz should exist"
      assert File.exist?(base64_path), "Base64 encoded file #{filename}.b64 should exist"
      
      # Verify compression worked
      original_size = File.size(Rails.root.join("public/playground/data", filename))
      compressed_size = File.size(compressed_path)
      
      assert compressed_size < original_size, "Compressed file should be smaller than original"
      assert compressed_size < original_size * 0.2, "Compression should achieve at least 80% reduction"
    end
  end
  
  test "manifest file contains correct metadata" do
    manifest_path = Rails.root.join("public/playground/data/manifest.json")
    assert File.exist?(manifest_path), "Manifest file should exist"
    
    manifest = JSON.parse(File.read(manifest_path))
    
    assert manifest["generated_at"].present?
    assert manifest["files"].present?
    
    %w[tailwind_colors.json spacing_values.json font_sizes.json completion_data.json].each do |filename|
      file_info = manifest["files"][filename]
      assert file_info.present?, "Manifest should contain info for #{filename}"
      assert file_info["original_size"] > 0
      assert file_info["compressed_size"] > 0
      assert file_info["checksum"].present?
    end
  end
  
  test "playground loads compressed data via base64" do
    get "/playground"
    assert_response :success
    
    # Check that the data manager is initialized
    assert_match(/PlaygroundDataManager/, response.body)
    assert_match(/DecompressionStream/, response.body)
    assert_match(/playground_data_v1/, response.body)
  end
  
  test "completion service accepts cached data" do
    cached_data = {
      "tailwind_colors" => [
        { "value" => "teal", "label" => "teal", "category" => "base-color" },
        { "value" => "blue-500", "label" => "blue-500", "category" => "color" }
      ]
    }
    
    post "/playground/completions", params: {
      context: "button.bg(",
      position: { lineNumber: 1, column: 11 },
      cached_data: cached_data
    }, as: :json
    
    assert_response :success
    
    json = JSON.parse(response.body)
    assert json["suggestions"].present?
  end
  
  test "signature help endpoint works" do
    get "/playground/signatures", params: { method: "vstack" }
    assert_response :success
    
    json = JSON.parse(response.body)
    signatures = json["signatures"]
    
    assert signatures.present?
    assert_equal 1, signatures.length
    
    sig = signatures.first
    assert_equal "vstack(spacing: Integer = 0, align: Symbol = :center, &block)", sig["label"]
    assert sig["documentation"].present?
    assert sig["parameters"].present?
    assert_equal 3, sig["parameters"].length
  end
end