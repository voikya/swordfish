# An image node
# Actual image data is stored at the document level, and can be
# retrieved by calling get_image(image_image) on the document
# object.

module Swordfish
  module Node
    class Image < Base

      attr_accessor :original_name

      # Override Base append because an image node should never have children
      def append(node)
        raise BadContentError
      end

      def to_html
        "<img src='#{@original_name}'>"
      end

    end
  end
end
