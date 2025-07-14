# frozen_string_literal: true

require 'json'
require 'zlib'
require 'base64'

namespace :playground do
  desc "Compress playground data files for faster loading"
  task compress_data: :environment do
    data_dir = Rails.root.join("public/playground/data")
    
    # Files to compress
    files = [
      "tailwind_colors.json",
      "spacing_values.json", 
      "font_sizes.json",
      "completion_data.json"
    ]
    
    files.each do |filename|
      input_path = data_dir.join(filename)
      output_path = data_dir.join(filename.gsub('.json', '.json.gz'))
      
      if File.exist?(input_path)
        puts "Compressing #{filename}..."
        
        # Read the original file
        original_data = File.read(input_path)
        original_size = original_data.bytesize
        
        # Compress using gzip
        compressed_data = Zlib::Deflate.deflate(original_data, Zlib::BEST_COMPRESSION)
        compressed_size = compressed_data.bytesize
        
        # Write compressed file
        File.binwrite(output_path, compressed_data)
        
        # Also create a base64 encoded version for easier loading in JS
        base64_path = data_dir.join(filename.gsub('.json', '.json.b64'))
        base64_data = Base64.encode64(compressed_data)
        File.write(base64_path, base64_data)
        
        # Calculate compression ratio
        ratio = ((original_size - compressed_size) / original_size.to_f * 100).round(1)
        
        puts "  Original: #{(original_size / 1024.0).round(1)}KB"
        puts "  Compressed: #{(compressed_size / 1024.0).round(1)}KB"
        puts "  Compression ratio: #{ratio}%"
        puts "  Saved to: #{output_path}"
        puts ""
      else
        puts "Skipping #{filename} - file not found"
      end
    end
    
    # Create a manifest file with metadata
    manifest = {
      generated_at: Time.now.iso8601,
      files: {}
    }
    
    files.each do |filename|
      input_path = data_dir.join(filename)
      if File.exist?(input_path)
        original_data = File.read(input_path)
        compressed_path = data_dir.join(filename.gsub('.json', '.json.gz'))
        compressed_data = File.exist?(compressed_path) ? File.read(compressed_path) : nil
        
        manifest[:files][filename] = {
          original_size: original_data.bytesize,
          compressed_size: compressed_data ? compressed_data.bytesize : nil,
          checksum: Digest::SHA256.hexdigest(original_data)
        }
      end
    end
    
    manifest_path = data_dir.join("manifest.json")
    File.write(manifest_path, JSON.pretty_generate(manifest))
    puts "Manifest written to: #{manifest_path}"
  end
end