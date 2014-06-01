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
      attr_accessor :caption

      # Override Base append because an image node should never have children
      def append(node)
        raise BadContentError
      end

      def to_html
        @caption ||= ""
        "<img src=\"#{CGI::escape(@path ? @path : @original_name)}\" alt=\"#{CGI::escapeHTML(@caption)}\" title=\"#{CGI::escapeHTML(@caption)}\" />"
      end

    end
  end
end
