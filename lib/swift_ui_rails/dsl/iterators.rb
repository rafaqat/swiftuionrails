# frozen_string_literal: true

module SwiftUIRails
  module DSL
    module Iterators
      # ForEach(items, id: :id) { |item| ... }
      # Mimics SwiftUI's ForEach structure for identifying data
      def ForEach(data, id: :id, &block)
        return unless data.respond_to?(:each)

        # In a real DOM-diffing world, we'd use the ID for keys.
        # For server-side rendering, we'll iterate.
        
        # Capture the result of iteration to return a composite element or render directly
        data.each_with_index do |item, index|
          # Calculate a unique key if possible
          key = if item.respond_to?(id)
                  item.send(id)
                elsif item.is_a?(Hash) && item[id]
                  item[id]
                else
                  index
                end

          # Execute the block
          # We might want to wrap this in a fragment if we were doing true diffing
          # For now, just yield
          yield(item)
        end
        
        # Return nil as this method outputs directly to the buffer via yield -> create_element
        nil
      end
    end
  end
end
