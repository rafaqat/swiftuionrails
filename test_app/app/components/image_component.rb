# frozen_string_literal: true

class ImageComponent < SwiftUIRails::Component::Base
  prop :src, type: String, default: "https://picsum.photos/400/400"
  prop :alt_text, type: String, default: "Sample image"
  prop :aspect_ratio, type: String, default: "square"
  prop :object_fit, type: String, default: "cover"
  prop :corner_radius, type: String, default: "none"
  prop :border, type: [TrueClass, FalseClass], default: false
  prop :grayscale, type: [TrueClass, FalseClass], default: false
  prop :blur, type: [TrueClass, FalseClass], default: false

  swift_ui do
    img = image(src, alt: alt_text)
    
    case aspect_ratio
    when "square"
      img = img.aspect_ratio("square")
    when "portrait"
      img = img.aspect_ratio("3/4")
    when "landscape"
      img = img.aspect_ratio("4/3")
    when "wide"
      img = img.aspect_ratio("16/9")
    end
    
    img = img.object_fit(object_fit) if object_fit != "cover"
    img = img.corner_radius(corner_radius) if corner_radius != "none"
    img = img.border if border
    img = img.grayscale if grayscale
    img = img.blur if blur
    
    img
  end
end