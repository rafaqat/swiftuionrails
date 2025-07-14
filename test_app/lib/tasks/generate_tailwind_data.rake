# frozen_string_literal: true

namespace :swift_ui do
  desc "Generate Tailwind color data for completions"
  task generate_tailwind_data: :environment do
    require "json"

    # Tailwind color palette
    colors = {
      slate: %w[50 100 200 300 400 500 600 700 800 900 950],
      gray: %w[50 100 200 300 400 500 600 700 800 900 950],
      zinc: %w[50 100 200 300 400 500 600 700 800 900 950],
      neutral: %w[50 100 200 300 400 500 600 700 800 900 950],
      stone: %w[50 100 200 300 400 500 600 700 800 900 950],
      red: %w[50 100 200 300 400 500 600 700 800 900 950],
      orange: %w[50 100 200 300 400 500 600 700 800 900 950],
      amber: %w[50 100 200 300 400 500 600 700 800 900 950],
      yellow: %w[50 100 200 300 400 500 600 700 800 900 950],
      lime: %w[50 100 200 300 400 500 600 700 800 900 950],
      green: %w[50 100 200 300 400 500 600 700 800 900 950],
      emerald: %w[50 100 200 300 400 500 600 700 800 900 950],
      teal: %w[50 100 200 300 400 500 600 700 800 900 950],
      cyan: %w[50 100 200 300 400 500 600 700 800 900 950],
      sky: %w[50 100 200 300 400 500 600 700 800 900 950],
      blue: %w[50 100 200 300 400 500 600 700 800 900 950],
      indigo: %w[50 100 200 300 400 500 600 700 800 900 950],
      violet: %w[50 100 200 300 400 500 600 700 800 900 950],
      purple: %w[50 100 200 300 400 500 600 700 800 900 950],
      fuchsia: %w[50 100 200 300 400 500 600 700 800 900 950],
      pink: %w[50 100 200 300 400 500 600 700 800 900 950],
      rose: %w[50 100 200 300 400 500 600 700 800 900 950]
    }

    # Generate color completions
    color_completions = []

    # Add base color names (without shade)
    colors.each_key do |color_name|
      color_completions << {
        value: color_name.to_s,
        label: color_name.to_s,
        category: "base-color",
        description: "Default shade (500) for #{color_name}"
      }
    end

    # Add all color-shade combinations
    colors.each do |color_name, shades|
      shades.each do |shade|
        color_completions << {
          value: "#{color_name}-#{shade}",
          label: "#{color_name}-#{shade}",
          category: "color",
          preview: true  # Could add actual color hex values here
        }
      end
    end

    # Add special base colors
    %w[white black transparent current inherit none].each do |color|
      color_completions.unshift({
        value: color,
        label: color,
        category: "base-color"
      })
    end

    # Spacing values
    spacing_values = %w[0 px 0.5 1 1.5 2 2.5 3 3.5 4 5 6 7 8 9 10 11 12 14 16 20 24 28 32 36 40 44 48 52 56 60 64 72 80 96]

    spacing_completions = spacing_values.map do |value|
      {
        value: value,
        label: value,
        category: "spacing",
        description: value == "px" ? "1px" : "#{value} × 0.25rem"
      }
    end

    # Font sizes
    font_sizes = {
      xs: "0.75rem",
      sm: "0.875rem",
      base: "1rem",
      lg: "1.125rem",
      xl: "1.25rem",
      "2xl": "1.5rem",
      "3xl": "1.875rem",
      "4xl": "2.25rem",
      "5xl": "3rem",
      "6xl": "3.75rem",
      "7xl": "4.5rem",
      "8xl": "6rem",
      "9xl": "8rem"
    }

    font_size_completions = font_sizes.map do |size, rem|
      {
        value: size.to_s,
        label: size.to_s,
        category: "font-size",
        description: rem
      }
    end

    # Write to JSON files
    output_dir = Rails.root.join("public", "playground", "data")
    FileUtils.mkdir_p(output_dir)

    File.write(
      output_dir.join("tailwind_colors.json"),
      JSON.pretty_generate(color_completions)
    )

    File.write(
      output_dir.join("spacing_values.json"),
      JSON.pretty_generate(spacing_completions)
    )

    File.write(
      output_dir.join("font_sizes.json"),
      JSON.pretty_generate(font_size_completions)
    )

    # Generate combined data file
    all_data = {
      version: Time.now.to_i,
      colors: color_completions,
      spacing: spacing_completions,
      font_sizes: font_size_completions
    }

    File.write(
      output_dir.join("completion_data.json"),
      JSON.pretty_generate(all_data)
    )

    puts "Generated Tailwind completion data in #{output_dir}"
    puts "- Colors: #{color_completions.size} entries"
    puts "- Spacing: #{spacing_completions.size} entries"
    puts "- Font sizes: #{font_size_completions.size} entries"
  end
end
