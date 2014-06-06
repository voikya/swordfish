# A raw content node
# This node simply outputs its content as-is, with no attempts to reformat or escape text

module Swordfish
  module Node
    class Raw < Base

      # Override Base append because a raw node should never have children
      def append(node)
        raise BadContentError
      end

      def to_html
        @content
      end

    end
  end
end
