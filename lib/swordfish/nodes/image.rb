# An image node
# Actual image data is stored at the document level, and can be
# retrieved by calling get_image(image_image) on the document
# object.

module Swordfish
  module Node
    class Image < Base

      # @original_name holds the name of the file as it is reported by the source document
      attr_accessor :original_name
      # @path holds a new name for the image that must be assigned explicitly
      attr_accessor :path

      # Override Base append because an image node should never have children
      def append(node)
        raise BadContentError
      end

      def to_html
        "<img src='#{@path ? @path : @original_name}'>"
      end

    end
  end
end
